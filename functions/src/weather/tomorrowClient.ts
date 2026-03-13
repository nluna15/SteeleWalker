import axios from "axios";
import { ForecastResponse, HourlyEntry, WeatherEntry } from "./types";

const TOMORROW_API_URL = "https://api.tomorrow.io/v4/timelines";

const REQUESTED_FIELDS = [
  "temperature",
  "temperatureApparent",
  "humidity",
  "windSpeed",
  "windDirection",
  "precipitationProbability",
  "precipitationType",
  "weatherCode",
  "uvIndex",
  "epaIndex",
];

/** Maps Tomorrow.io precipitationType integer to a string label. */
function mapPrecipType(code: number): string | null {
  switch (code) {
    case 0: return null;
    case 1: return "rain";
    case 2: return "snow";
    case 3: return "freezing_rain";
    case 4: return "ice_pellets";
    default: return null;
  }
}

/** Maps Tomorrow.io weatherCode to a human-readable condition string. */
function mapConditionText(code: number): string {
  const map: Record<number, string> = {
    1000: "Clear",
    1001: "Cloudy",
    1100: "Mostly Clear",
    1101: "Partly Cloudy",
    1102: "Mostly Cloudy",
    2000: "Fog",
    2100: "Light Fog",
    3000: "Light Wind",
    3001: "Wind",
    3002: "Strong Wind",
    4000: "Drizzle",
    4001: "Rain",
    4200: "Light Rain",
    4201: "Heavy Rain",
    5000: "Snow",
    5001: "Flurries",
    5100: "Light Snow",
    5101: "Heavy Snow",
    6000: "Freezing Drizzle",
    6001: "Freezing Rain",
    6200: "Light Freezing Rain",
    6201: "Heavy Freezing Rain",
    7000: "Ice Pellets",
    7101: "Heavy Ice Pellets",
    7102: "Light Ice Pellets",
    8000: "Thunderstorm",
  };
  return map[code] ?? "Unknown";
}

/** Converts a UTC ISO string to a local ISO string with timezone offset. */
function toLocalTimestamp(utcIso: string, timezone: string): string {
  const date = new Date(utcIso);
  // Intl.DateTimeFormat to get the local parts
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

  // Convert "GMT-8" → "-08:00", "GMT+5:30" → "+05:30"
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

/** Raw Tomorrow.io interval shape (subset of fields we use). */
interface TomorrowInterval {
  startTime: string;
  values: {
    temperature?: number;
    temperatureApparent?: number;
    humidity?: number;
    windSpeed?: number;
    windDirection?: number;
    precipitationProbability?: number;
    precipitationType?: number;
    weatherCode?: number;
    uvIndex?: number;
    epaIndex?: number;
  };
}

/** Raw Tomorrow.io timelines response. */
interface TomorrowResponse {
  data: {
    timelines: Array<{
      timestep: string;
      timezone: string;
      intervals: TomorrowInterval[];
    }>;
  };
}

function intervalToEntry(
  interval: TomorrowInterval,
  capturedAt: string,
  timezone: string,
  includeLocalTimestamp: true
): HourlyEntry;
function intervalToEntry(
  interval: TomorrowInterval,
  capturedAt: string,
  timezone: string,
  includeLocalTimestamp: false
): WeatherEntry;
function intervalToEntry(
  interval: TomorrowInterval,
  capturedAt: string,
  timezone: string,
  includeLocalTimestamp: boolean
): WeatherEntry | HourlyEntry {
  const v = interval.values;
  const base: WeatherEntry = {
    temperature_f: v.temperature ?? 0,
    feels_like_f: v.temperatureApparent ?? 0,
    humidity: Math.round(v.humidity ?? 0),
    wind_speed_mph: v.windSpeed ?? 0,
    precip_probability: Math.round(v.precipitationProbability ?? 0),
    precip_type: mapPrecipType(v.precipitationType ?? 0),
    weather_code: v.weatherCode ?? 0,
    condition_text: mapConditionText(v.weatherCode ?? 0),
    uv_index: Math.round(v.uvIndex ?? 0),
    aqi: v.epaIndex !== undefined ? Math.round(v.epaIndex) : null,
    wind_direction_deg: Math.round(v.windDirection ?? 0),
    captured_at: capturedAt,
  };

  if (!includeLocalTimestamp) return base;

  return {
    ...base,
    local_timestamp: toLocalTimestamp(interval.startTime, timezone),
  };
}

/**
 * Fetches current conditions + 48 hours of hourly forecast from Tomorrow.io.
 *
 * @param lat  Latitude
 * @param lon  Longitude
 * @param _units  Reserved for future metric support; Tomorrow.io imperial is the default.
 */
export async function fetchForecast(
  lat: number,
  lon: number,
  _units: string = "imperial"
): Promise<ForecastResponse> {
  const apiKey = process.env.TOMORROW_IO_API_KEY;
  if (!apiKey) {
    throw new Error("TOMORROW_IO_API_KEY environment variable is not set");
  }

  const now = new Date();
  const endTime = new Date(now.getTime() + 48 * 60 * 60 * 1000);

  const payload = {
    location: `${lat},${lon}`,
    fields: REQUESTED_FIELDS,
    timesteps: ["current", "1h"],
    startTime: now.toISOString(),
    endTime: endTime.toISOString(),
    units: "imperial",
  };

  const response = await axios.post<TomorrowResponse>(
    `${TOMORROW_API_URL}?apikey=${apiKey}`,
    payload,
    { headers: { "Content-Type": "application/json" } }
  );

  const timelines = response.data.data.timelines;
  const capturedAt = now.toISOString();

  const currentTimeline = timelines.find((t) => t.timestep === "current");
  const hourlyTimeline = timelines.find((t) => t.timestep === "1h");

  if (!currentTimeline || !currentTimeline.intervals.length) {
    throw new Error("Tomorrow.io returned no current conditions data");
  }
  if (!hourlyTimeline || !hourlyTimeline.intervals.length) {
    throw new Error("Tomorrow.io returned no hourly forecast data");
  }

  const timezone = hourlyTimeline.timezone || currentTimeline.timezone || "UTC";

  const current = intervalToEntry(
    currentTimeline.intervals[0],
    capturedAt,
    timezone,
    false
  );

  const hourly: HourlyEntry[] = hourlyTimeline.intervals
    .slice(0, 48)
    .map((interval) =>
      intervalToEntry(interval, capturedAt, timezone, true)
    );

  return { current, hourly, timezone };
}
