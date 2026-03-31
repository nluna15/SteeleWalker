import {
  RecommendationLevel as L,
  levelToKey,
  levelToMaxDuration,
  type DogRiskProfile,
  type DogRecommendation,
  type HourlyRecommendation,
  type DogRecommendationEntry,
  type HouseholdRecommendation,
  type FirestoreDog,
  type WeatherEntry,
  type HourlyEntry,
} from "./types";
import { buildRiskProfile } from "./riskProfile";
import { evaluateHardStops } from "./hardStops";
import { applyModifiers } from "./modifiers";

/**
 * Convert a UTC ISO timestamp to a local ISO timestamp with timezone offset.
 * Uses Intl.DateTimeFormat to resolve the exact offset for the given timezone.
 */
function toLocalTimestamp(utcIso: string, timezone: string): string {
  const date = new Date(utcIso);
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
    timeZoneName: "shortOffset",
  });

  const parts = formatter.formatToParts(date);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";

  const year = get("year");
  const month = get("month");
  const day = get("day");
  const hour = get("hour") === "24" ? "00" : get("hour");
  const minute = get("minute");
  const second = get("second");
  const offsetRaw = get("timeZoneName"); // e.g. "GMT-8" or "GMT+5:30"

  let offset = "+00:00";
  const offsetMatch = offsetRaw.match(/GMT([+-])(\d{1,2})(?::(\d{2}))?/);
  if (offsetMatch) {
    const sign = offsetMatch[1];
    const hours = offsetMatch[2].padStart(2, "0");
    const minutes = (offsetMatch[3] ?? "00").padStart(2, "0");
    offset = `${sign}${hours}:${minutes}`;
  }

  return `${year}-${month}-${day}T${hour}:${minute}:${second}${offset}`;
}

/** Evaluate a single weather entry against a dog's risk profile. */
function evaluateRecommendation(
  weather: WeatherEntry | HourlyEntry,
  profile: DogRiskProfile
): { level: L; hardStopReasons: string[]; modifierReasons: string[] } {
  const hardStops = evaluateHardStops(weather, profile);
  const modifiers = applyModifiers(
    hardStops.ceiling,
    weather,
    profile,
    hardStops.humidityApplied
  );

  return {
    level: modifiers.level,
    hardStopReasons: hardStops.reasons,
    modifierReasons: modifiers.reasons,
  };
}

/** Build full recommendation for a single dog across current + hourly. */
export function evaluateForDog(
  dog: FirestoreDog,
  current: WeatherEntry,
  hourly: HourlyEntry[],
  timezone: string
): DogRecommendationEntry {
  const profile = buildRiskProfile(dog);

  // Attach a local_timestamp to the current entry so evaluators (e.g. pavement
  // burn) can determine the exact local hour using the request's timezone.
  const currentWithTs: HourlyEntry = {
    ...current,
    local_timestamp: toLocalTimestamp(current.captured_at, timezone),
  };

  // Current
  const currentResult = evaluateRecommendation(currentWithTs, profile);
  const currentRec: DogRecommendation = {
    dogId: dog.id,
    dogName: dog.name,
    level: currentResult.level,
    levelKey: levelToKey(currentResult.level),
    maxDurationMin: levelToMaxDuration(currentResult.level),
    reasons: [...currentResult.hardStopReasons, ...currentResult.modifierReasons].filter(Boolean),
    hardStopReasons: currentResult.hardStopReasons.filter(Boolean),
    modifierReasons: currentResult.modifierReasons.filter(Boolean),
  };

  // Hourly — carry forward current.aqi where hourly aqi is null
  const hourlyRecs: HourlyRecommendation[] = hourly.map((h) => {
    const entry: HourlyEntry = h.aqi === null && current.aqi !== null
      ? { ...h, aqi: current.aqi }
      : h;

    const result = evaluateRecommendation(entry, profile);
    return {
      local_timestamp: h.local_timestamp,
      level: result.level,
      levelKey: levelToKey(result.level),
      reasons: [...result.hardStopReasons, ...result.modifierReasons].filter(Boolean),
    };
  });

  return {
    dogId: dog.id,
    dogName: dog.name,
    current: currentRec,
    hourly: hourlyRecs,
  };
}

/** Evaluate a single weather entry across all dogs, returning household-level recommendation. */
export function evaluateHouseholdForWeather(
  dogs: FirestoreDog[],
  weather: WeatherEntry | HourlyEntry,
  timezone: string
): DogRecommendation {
  let maxLevel = L.optimal;
  const allReasons: string[] = [];

  for (const dog of dogs) {
    const profile = buildRiskProfile(dog);
    const result = evaluateRecommendation(weather, profile);
    if (result.level > maxLevel) {
      maxLevel = result.level;
    }
    allReasons.push(...result.hardStopReasons, ...result.modifierReasons);
  }

  return {
    dogId: "household",
    dogName: "Household",
    level: maxLevel,
    levelKey: levelToKey(maxLevel),
    maxDurationMin: levelToMaxDuration(maxLevel),
    reasons: [...new Set(allReasons.filter(Boolean))],
    hardStopReasons: [],
    modifierReasons: [],
  };
}

/** Compute household-level recommendation (most restrictive across all dogs). */
export function evaluateHousehold(
  dogResults: DogRecommendationEntry[]
): HouseholdRecommendation {
  if (dogResults.length === 0) {
    throw new Error("At least one dog result is required");
  }

  // Current — most restrictive
  let currentLevel = L.optimal;
  const currentReasons: string[] = [];
  for (const d of dogResults) {
    if (d.current.level > currentLevel) {
      currentLevel = d.current.level as L;
    }
    currentReasons.push(...d.current.reasons);
  }

  const householdCurrent: DogRecommendation = {
    dogId: "household",
    dogName: "Household",
    level: currentLevel,
    levelKey: levelToKey(currentLevel),
    maxDurationMin: levelToMaxDuration(currentLevel),
    reasons: [...new Set(currentReasons)],
    hardStopReasons: [],
    modifierReasons: [],
  };

  // Hourly — most restrictive per time slot
  const firstDog = dogResults[0];
  const householdHourly: HourlyRecommendation[] = firstDog.hourly.map(
    (slot, i) => {
      let maxLevel = L.optimal;
      const allReasons: string[] = [];

      for (const d of dogResults) {
        const dSlot = d.hourly[i];
        if (dSlot && dSlot.level > maxLevel) {
          maxLevel = dSlot.level as L;
        }
        if (dSlot) allReasons.push(...dSlot.reasons);
      }

      return {
        local_timestamp: slot.local_timestamp,
        level: maxLevel,
        levelKey: levelToKey(maxLevel),
        reasons: [...new Set(allReasons)],
      };
    }
  );

  return { current: householdCurrent, hourly: householdHourly };
}
