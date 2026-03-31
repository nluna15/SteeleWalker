import type { Request, Response } from "express";
import { FieldPath } from "firebase-admin/firestore";
import { verifyToken } from "../auth";
import { getDb } from "../firestore";
import type {
  FirestoreDog,
  FirestoreWalkingSchedule,
  ForecastResponse,
  HourlyEntry,
  RecommendationResponse,
  ScheduledWalkRecommendation,
  WalkSlot,
} from "./types";
import { evaluateForDog, evaluateHousehold, evaluateHouseholdForWeather } from "./engine";

function errorResponse(
  res: Response,
  status: number,
  message: string,
  code: string,
  details?: Record<string, unknown>
): void {
  res
    .status(status)
    .json({ error: message, code, ...(details ? { details } : {}) });
}

interface RecommendationRequestBody {
  dogIds: string[];
  weather: ForecastResponse;
}

/**
 * POST /walkRecommendation
 *
 * Body: { dogIds: string[], weather: ForecastResponse }
 * Returns: RecommendationResponse
 */
export async function recommendationHandler(
  req: Request,
  res: Response
): Promise<void> {
  if (req.method !== "POST") {
    errorResponse(res, 405, "Method not allowed", "METHOD_NOT_ALLOWED");
    return;
  }

  // 1. Authenticate
  let uid: string;
  try {
    uid = await verifyToken(req.headers.authorization);
  } catch (err: unknown) {
    const e = err as { status?: number; message?: string };
    errorResponse(
      res,
      e.status ?? 401,
      e.message ?? "Unauthorized",
      "UNAUTHORIZED"
    );
    return;
  }

  // 2. Validate request body
  const body = req.body as RecommendationRequestBody;

  if (!body.dogIds || !Array.isArray(body.dogIds) || body.dogIds.length === 0) {
    errorResponse(res, 400, "dogIds must be a non-empty array", "INVALID_REQUEST");
    return;
  }

  if (body.dogIds.length > 5) {
    errorResponse(res, 400, "Maximum 5 dogs per request", "INVALID_REQUEST");
    return;
  }

  if (!body.weather || !body.weather.current) {
    errorResponse(res, 400, "weather.current is required", "INVALID_REQUEST");
    return;
  }

  if (
    !body.weather.hourly ||
    !Array.isArray(body.weather.hourly) ||
    body.weather.hourly.length === 0
  ) {
    errorResponse(
      res,
      400,
      "weather.hourly must be a non-empty array",
      "INVALID_REQUEST"
    );
    return;
  }

  if (body.weather.hourly.length > 50) {
    errorResponse(
      res,
      400,
      "weather.hourly must not exceed 50 entries",
      "INVALID_REQUEST"
    );
    return;
  }

  // 3. Fetch dogs from Firestore
  const db = getDb();
  const dogsSnap = await db
    .collection("dogs")
    .where(FieldPath.documentId(), "in", body.dogIds)
    .get();

  if (dogsSnap.empty) {
    errorResponse(res, 404, "No dogs found for the provided IDs", "NOT_FOUND");
    return;
  }

  const dogs: FirestoreDog[] = [];
  for (const doc of dogsSnap.docs) {
    const data = doc.data();

    // Ownership check
    if (data.user_id !== uid) {
      errorResponse(
        res,
        403,
        `Dog ${doc.id} does not belong to this user`,
        "FORBIDDEN"
      );
      return;
    }

    // Active check
    if (data.is_active === false) {
      errorResponse(
        res,
        400,
        `Dog ${doc.id} is not active`,
        "INVALID_REQUEST"
      );
      return;
    }

    dogs.push({
      id: doc.id,
      user_id: data.user_id,
      name: data.name,
      breed_ids: data.breed_ids ?? [],
      birth_year: data.birth_year ?? null,
      birth_month: data.birth_month ?? null,
      size: data.size,
      health_conditions: data.health_conditions ?? [],
      sensitivities: data.sensitivities ?? [],
      is_active: data.is_active,
    });
  }

  // Check all requested dogs were found
  if (dogs.length !== body.dogIds.length) {
    const foundIds = new Set(dogs.map((d) => d.id));
    const missing = body.dogIds.filter((id) => !foundIds.has(id));
    errorResponse(
      res,
      404,
      `Dogs not found: ${missing.join(", ")}`,
      "NOT_FOUND"
    );
    return;
  }

  // 4. Evaluate recommendations
  const timezone = body.weather.timezone || "UTC";
  const dogResults = dogs.map((dog) =>
    evaluateForDog(dog, body.weather.current, body.weather.hourly, timezone)
  );

  const household = evaluateHousehold(dogResults);

  // 5. Fetch walking schedules and resolve next walks
  let scheduledWalks: ScheduledWalkRecommendation[] = [];
  try {
    const schedulesSnap = await db
      .collection("walking_schedules")
      .where("user_id", "==", uid)
      .limit(2)
      .get();

    if (!schedulesSnap.empty) {
      const schedules: FirestoreWalkingSchedule[] = schedulesSnap.docs.map(
        (doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            user_id: data.user_id,
            schedule_type: data.schedule_type,
            walks_per_day: data.walks_per_day,
            slots: data.slots ?? [],
          } as FirestoreWalkingSchedule;
        }
      );

      scheduledWalks = resolveNextWalks(
        schedules,
        timezone,
        body.weather.hourly,
        dogs,
        4
      );
    }
  } catch (err) {
    // Non-fatal — return response without scheduled walks
    console.warn("Failed to resolve scheduled walks:", err);
  }

  const response: RecommendationResponse = {
    dogs: dogResults,
    household,
    scheduled_walks: scheduledWalks,
    generated_at: new Date().toISOString(),
  };

  res.status(200).json(response);
}

// --- Schedule resolution helpers ---

interface ResolvedSlot {
  preferred_time: string;
  duration_minutes: number;
  date: string;          // "YYYY-MM-DD" in local timezone
  day_label: string;
  schedule_type: string;
}

/** Day names for day_label when neither today nor tomorrow. */
const DAY_NAMES = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

/**
 * Resolve the next `limit` walks chronologically from the user's walking
 * schedules, map each to an hourly forecast entry, and evaluate the
 * household-level recommendation.
 */
function resolveNextWalks(
  schedules: FirestoreWalkingSchedule[],
  timezone: string,
  hourly: HourlyEntry[],
  dogs: FirestoreDog[],
  limit: number
): ScheduledWalkRecommendation[] {
  // Get current local date/time components using the forecast timezone.
  const now = new Date();
  const localParts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
    weekday: "short",
  }).formatToParts(now);

  const get = (type: string) =>
    localParts.find((p) => p.type === type)?.value ?? "";
  const nowHour = parseInt(get("hour") === "24" ? "0" : get("hour"), 10);
  const nowMinute = parseInt(get("minute"), 10);
  const nowTimeStr = `${String(nowHour).padStart(2, "0")}:${String(nowMinute).padStart(2, "0")}`;

  // Build a map of schedule_type → slots
  const scheduleMap = new Map<string, WalkSlot[]>();
  for (const s of schedules) {
    scheduleMap.set(s.schedule_type, s.slots);
  }

  const resolved: ResolvedSlot[] = [];

  // Iterate up to 3 days (today, tomorrow, day after)
  for (let dayOffset = 0; dayOffset < 3 && resolved.length < limit; dayOffset++) {
    const targetDate = new Date(now.getTime() + dayOffset * 86400000);
    const targetParts = new Intl.DateTimeFormat("en-CA", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      weekday: "short",
    }).formatToParts(targetDate);

    const tGet = (type: string) =>
      targetParts.find((p) => p.type === type)?.value ?? "";
    const dateStr = `${tGet("year")}-${tGet("month")}-${tGet("day")}`;
    const weekday = tGet("weekday"); // "Mon", "Tue", etc.

    // Determine schedule type for this day
    const isWeekend = weekday === "Sat" || weekday === "Sun";
    const scheduleType = isWeekend ? "weekend" : "weekday";
    const slots = scheduleMap.get(scheduleType);
    if (!slots || slots.length === 0) continue;

    // Determine day label
    let dayLabel: string;
    if (dayOffset === 0) {
      dayLabel = "Today";
    } else if (dayOffset === 1) {
      dayLabel = "Tomorrow";
    } else {
      // Map weekday abbreviation to full index
      const dayIndex = targetDate.getDay();
      dayLabel = DAY_NAMES[dayIndex];
      // Fallback: use Intl to get the full day name in the target timezone
      if (!dayLabel) {
        dayLabel = new Intl.DateTimeFormat("en-US", {
          timeZone: timezone,
          weekday: "long",
        }).format(targetDate);
      }
    }

    // Sort slots by preferred_time
    const sortedSlots = [...slots].sort((a, b) =>
      a.preferred_time.localeCompare(b.preferred_time)
    );

    for (const slot of sortedSlots) {
      if (resolved.length >= limit) break;

      // For today, skip slots whose preferred_time has already passed
      if (dayOffset === 0 && slot.preferred_time <= nowTimeStr) continue;

      resolved.push({
        preferred_time: slot.preferred_time,
        duration_minutes: slot.duration_minutes,
        date: dateStr,
        day_label: dayLabel,
        schedule_type: scheduleType,
      });
    }
  }

  // Map each resolved slot to a forecast entry and evaluate
  return resolved.map((slot) => {
    // Floor preferred_time to the containing hour
    const [hourStr] = slot.preferred_time.split(":");
    const slotHour = parseInt(hourStr, 10);

    // Find the matching hourly entry by date + hour
    const matchedEntry = hourly.find((h) => {
      // h.local_timestamp is like "2026-03-22T08:00:00-07:00"
      const dateMatch = h.local_timestamp.startsWith(slot.date);
      if (!dateMatch) return false;
      const timeMatch = h.local_timestamp.substring(11, 13);
      return parseInt(timeMatch, 10) === slotHour;
    });

    // Build the local_timestamp for the slot
    const localTimestamp = buildLocalTimestamp(slot.date, slot.preferred_time, timezone);

    // Evaluate recommendation
    let recommendation;
    if (matchedEntry) {
      recommendation = evaluateHouseholdForWeather(dogs, matchedEntry, timezone);
    } else {
      // No matching forecast (out of 48h window) — return optimal as fallback
      recommendation = {
        dogId: "household",
        dogName: "Household",
        level: 0,
        levelKey: "optimal",
        maxDurationMin: null,
        reasons: [],
        hardStopReasons: [],
        modifierReasons: [],
      };
    }

    return {
      preferred_time: slot.preferred_time,
      local_timestamp: localTimestamp,
      day_label: slot.day_label,
      schedule_type: slot.schedule_type,
      duration_minutes: slot.duration_minutes,
      recommendation,
    };
  });
}

/**
 * Build an ISO 8601 timestamp with timezone offset for a date + time in a
 * given IANA timezone.
 */
function buildLocalTimestamp(
  dateStr: string,
  timeStr: string,
  timezone: string
): string {
  // Create a UTC date close to the target, then use Intl to get the offset
  const [year, month, day] = dateStr.split("-").map(Number);
  const [hour, minute] = timeStr.split(":").map(Number);
  const approxDate = new Date(
    Date.UTC(year, month - 1, day, hour, minute, 0)
  );

  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    timeZoneName: "shortOffset",
  });
  const parts = formatter.formatToParts(approxDate);
  const offsetRaw =
    parts.find((p) => p.type === "timeZoneName")?.value ?? "GMT";

  let offset = "+00:00";
  const offsetMatch = offsetRaw.match(/GMT([+-])(\d{1,2})(?::(\d{2}))?/);
  if (offsetMatch) {
    const sign = offsetMatch[1];
    const hours = offsetMatch[2].padStart(2, "0");
    const minutes = (offsetMatch[3] ?? "00").padStart(2, "0");
    offset = `${sign}${hours}:${minutes}`;
  }

  return `${dateStr}T${timeStr}:00${offset}`;
}
