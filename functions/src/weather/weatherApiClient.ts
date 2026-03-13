import axios from "axios";
import { ForecastResponse, HourlyEntry, WeatherEntry } from "./types";

const WEATHER_API_URL = "https://api.weatherapi.com/v1/forecast.json";

/** Derive precipitation type from WeatherAPI condition code. */
function mapPrecipType(code: number): string | null {
  // Snow
  if (
    code === 1066 || code === 1114 ||
    (code >= 1210 && code <= 1225) ||
    (code >= 1255 && code <= 1258)
  ) {
    return "snow";
  }
  // Rain
  if (
    code === 1063 ||
    (code >= 1150 && code <= 1201) ||
    (code >= 1240 && code <= 1246)
  ) {
    return "rain";
  }
  // Freezing rain
  if (
    code === 1069 ||
    (code >= 1204 && code <= 1207) ||
    (code >= 1249 && code <= 1252)
  ) {
    return "freezing_rain";
  }
  // Ice pellets
  if (code === 1237 || (code >= 1261 && code <= 1264)) {
    return "ice_pellets";
  }
  return null;
}

/** Derive precip type from chance_of_rain / chance_of_snow percentages. */
function precipTypeFromChances(
  chanceOfRain: number,
  chanceOfSnow: number
): string | null {
  if (chanceOfSnow > chanceOfRain) return "snow";
  if (chanceOfRain > 0) return "rain";
  return null;
}

/** Converts a UTC ISO string to a local ISO string with timezone offset. */
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

/** Convert WeatherAPI hour time string ("2026-03-04 08:00") to UTC ISO. */
function hourTimeToUtc(hourTime: string, timezone: string): string {
  // Parse as local time in the given timezone by creating a date string
  // WeatherAPI returns times in local timezone: "2026-03-04 08:00"
  const [datePart, timePart] = hourTime.split(" ");
  const [year, month, day] = datePart.split("-").map(Number);
  const [hour, minute] = timePart.split(":").map(Number);

  // Create a formatter that can tell us the offset for this timezone
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    timeZoneName: "shortOffset",
  });

  // Use a reference date to get the timezone offset
  const refDate = new Date(`${datePart}T${timePart}:00Z`);
  const parts = formatter.formatToParts(refDate);
  const offsetRaw = parts.find((p) => p.type === "timeZoneName")?.value ?? "GMT";

  let offsetMinutes = 0;
  const offsetMatch = offsetRaw.match(/GMT([+-])(\d{1,2})(?::(\d{2}))?/);
  if (offsetMatch) {
    const sign = offsetMatch[1] === "+" ? 1 : -1;
    const hrs = parseInt(offsetMatch[2], 10);
    const mins = parseInt(offsetMatch[3] ?? "0", 10);
    offsetMinutes = sign * (hrs * 60 + mins);
  }

  // Construct UTC date by subtracting the offset
  const localMs = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
  const utcMs = localMs - offsetMinutes * 60 * 1000;
  return new Date(utcMs).toISOString();
}

/* ---------- WeatherAPI response shapes (subset we use) ---------- */

interface WeatherApiCondition {
  text: string;
  code: number;
}

interface WeatherApiCurrent {
  temp_f: number;
  feelslike_f: number;
  humidity: number;
  wind_mph: number;
  wind_degree: number;
  condition: WeatherApiCondition;
  uv: number;
  air_quality?: {
    "us-epa-index"?: number;
  };
}

interface WeatherApiHour {
  time: string; // "2026-03-04 08:00"
  time_epoch: number;
  temp_f: number;
  feelslike_f: number;
  humidity: number;
  wind_mph: number;
  wind_degree: number;
  chance_of_rain: number;
  chance_of_snow: number;
  condition: WeatherApiCondition;
  uv: number;
}

interface WeatherApiForecastDay {
  hour: WeatherApiHour[];
}

interface WeatherApiResponse {
  location: {
    tz_id: string; // IANA timezone
  };
  current: WeatherApiCurrent;
  forecast: {
    forecastday: WeatherApiForecastDay[];
  };
}

/**
 * Fetches current conditions + 48 hours of hourly forecast from WeatherAPI.
 *
 * @param lat  Latitude
 * @param lon  Longitude
 * @param _units  Reserved for future metric support.
 */
export async function fetchForecast(
  lat: number,
  lon: number,
  _units: string = "imperial"
): Promise<ForecastResponse> {
  const apiKey = process.env.WEATHER_API_KEY;
  if (!apiKey) {
    throw new Error("WEATHER_API_KEY environment variable is not set");
  }

  const response = await axios.get<WeatherApiResponse>(WEATHER_API_URL, {
    params: {
      key: apiKey,
      q: `${lat},${lon}`,
      days: 2,
      aqi: "yes",
    },
  });

  const data = response.data;
  const timezone = data.location.tz_id || "UTC";
  const capturedAt = new Date().toISOString();

  // --- Current conditions ---
  const cur = data.current;
  if (!cur) {
    throw new Error("Weather provider returned no current conditions data");
  }

  // Get first forecast hour for precip probability on current
  const allHours = data.forecast.forecastday.flatMap((d) => d.hour);
  if (!allHours.length) {
    throw new Error("Weather provider returned no hourly forecast data");
  }

  const firstHour = allHours[0];

  const current: WeatherEntry = {
    temperature_f: cur.temp_f,
    feels_like_f: cur.feelslike_f,
    humidity: Math.round(cur.humidity),
    wind_speed_mph: cur.wind_mph,
    wind_direction_deg: Math.round(cur.wind_degree),
    precip_probability: Math.round(
      Math.max(firstHour.chance_of_rain, firstHour.chance_of_snow)
    ),
    precip_type:
      mapPrecipType(cur.condition.code) ??
      precipTypeFromChances(firstHour.chance_of_rain, firstHour.chance_of_snow),
    weather_code: cur.condition.code,
    condition_text: cur.condition.text,
    uv_index: Math.round(cur.uv),
    aqi: cur.air_quality?.["us-epa-index"] != null
      ? Math.round(cur.air_quality["us-epa-index"])
      : null,
    captured_at: capturedAt,
  };

  // --- Hourly forecast ---
  const hourly: HourlyEntry[] = allHours.slice(0, 48).map((h) => {
    const utcIso = hourTimeToUtc(h.time, timezone);
    return {
      temperature_f: h.temp_f,
      feels_like_f: h.feelslike_f,
      humidity: Math.round(h.humidity),
      wind_speed_mph: h.wind_mph,
      wind_direction_deg: Math.round(h.wind_degree),
      precip_probability: Math.round(Math.max(h.chance_of_rain, h.chance_of_snow)),
      precip_type:
        mapPrecipType(h.condition.code) ??
        precipTypeFromChances(h.chance_of_rain, h.chance_of_snow),
      weather_code: h.condition.code,
      condition_text: h.condition.text,
      uv_index: Math.round(h.uv),
      aqi: null, // WeatherAPI only provides AQI on current
      captured_at: capturedAt,
      local_timestamp: toLocalTimestamp(utcIso, timezone),
    };
  });

  return { current, hourly, timezone };
}
