/**
 * A single weather reading — matches WeatherSnapshot.swift plus `aqi`.
 * Used for both the `current` entry and each `hourly` entry.
 */
export interface WeatherEntry {
  temperature_f: number;
  feels_like_f: number;
  humidity: number;
  wind_speed_mph: number;
  precip_probability: number;
  precip_type: string | null;
  weather_code: number;
  condition_text: string;
  uv_index: number;
  /** EPA AQI (0–500+). null when Tomorrow.io returns no data for the location. */
  aqi: number | null;
  /** ISO 8601 UTC timestamp when Tomorrow.io data was captured. */
  captured_at: string;
}

/**
 * A single hourly forecast entry. Extends WeatherEntry with a timezone-aware
 * local timestamp so the iOS client can display times in the user's local zone.
 */
export interface HourlyEntry extends WeatherEntry {
  /** ISO 8601 timestamp with timezone offset, e.g. "2026-03-04T08:00:00-08:00". */
  local_timestamp: string;
}

/**
 * Full response shape for GET /weather/forecast/hourly.
 */
export interface ForecastResponse {
  current: WeatherEntry;
  /** 48 hourly forecast entries. */
  hourly: HourlyEntry[];
  /** IANA timezone of the queried location, e.g. "America/Los_Angeles". */
  timezone: string;
}
