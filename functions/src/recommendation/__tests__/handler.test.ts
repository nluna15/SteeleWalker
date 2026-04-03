import { getWindowBoundsForPreferredTime, pickBestHourInWindow } from "../handler";
import type { FirestoreDog, HourlyEntry, WeatherEntry } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function baseDog(overrides: Partial<FirestoreDog> = {}): FirestoreDog {
  return {
    id: "dog-1",
    user_id: "user-1",
    name: "Buddy",
    breed_ids: [],
    birth_year: 2020,
    birth_month: 6,
    size: "medium",
    health_conditions: [],
    sensitivities: [],
    is_active: true,
    ...overrides,
  };
}

function baseWeather(overrides: Partial<WeatherEntry> = {}): WeatherEntry {
  return {
    temperature_f: 72,
    feels_like_f: 72,
    humidity: 40,
    wind_speed_mph: 5,
    precip_probability: 0,
    precip_type: null,
    weather_code: 1000,
    condition_text: "Sunny",
    uv_index: 3,
    aqi: null,
    wind_direction_deg: 180,
    captured_at: "2026-07-15T15:00:00Z",
    ...overrides,
  };
}

function makeHourly(localTimestamp: string, overrides: Partial<WeatherEntry> = {}): HourlyEntry {
  return { ...baseWeather(overrides), local_timestamp: localTimestamp };
}

const DATE = "2026-07-15";
const TIMEZONE = "America/Los_Angeles";
const DOGS = [baseDog()];

// ---------------------------------------------------------------------------
// getWindowBoundsForPreferredTime
// ---------------------------------------------------------------------------

describe("getWindowBoundsForPreferredTime", () => {
  it("maps morning preferred time to morning window", () => {
    expect(getWindowBoundsForPreferredTime("07:00")).toEqual({ startHour: 7, endHour: 9 });
    expect(getWindowBoundsForPreferredTime("08:30")).toEqual({ startHour: 7, endHour: 9 });
    expect(getWindowBoundsForPreferredTime("09:00")).toEqual({ startHour: 7, endHour: 9 });
  });

  it("maps midday preferred time to midday window", () => {
    expect(getWindowBoundsForPreferredTime("11:00")).toEqual({ startHour: 11, endHour: 13 });
    expect(getWindowBoundsForPreferredTime("12:00")).toEqual({ startHour: 11, endHour: 13 });
  });

  it("maps afternoon preferred time to afternoon window", () => {
    expect(getWindowBoundsForPreferredTime("14:00")).toEqual({ startHour: 14, endHour: 17 });
    expect(getWindowBoundsForPreferredTime("15:00")).toEqual({ startHour: 14, endHour: 17 });
    expect(getWindowBoundsForPreferredTime("17:00")).toEqual({ startHour: 14, endHour: 17 });
  });

  it("maps evening preferred time to evening window", () => {
    expect(getWindowBoundsForPreferredTime("18:00")).toEqual({ startHour: 18, endHour: 20 });
    expect(getWindowBoundsForPreferredTime("19:30")).toEqual({ startHour: 18, endHour: 20 });
  });

  it("falls back to ±1 hour for times outside named windows", () => {
    // 10:00 is between midday and morning windows
    expect(getWindowBoundsForPreferredTime("10:00")).toEqual({ startHour: 9, endHour: 11 });
    // 22:00 is outside all windows
    expect(getWindowBoundsForPreferredTime("22:00")).toEqual({ startHour: 21, endHour: 23 });
  });

  it("clamps fallback window to valid hour range", () => {
    expect(getWindowBoundsForPreferredTime("00:00")).toEqual({ startHour: 0, endHour: 1 });
    expect(getWindowBoundsForPreferredTime("23:00")).toEqual({ startHour: 22, endHour: 23 });
  });
});

// ---------------------------------------------------------------------------
// pickBestHourInWindow
// ---------------------------------------------------------------------------

describe("pickBestHourInWindow", () => {
  it("returns undefined when no hourly entries fall within the window", () => {
    const hourly = [
      makeHourly(`${DATE}T08:00:00-07:00`), // outside afternoon window
    ];
    const result = pickBestHourInWindow(hourly, DATE, 15, 14, 17, DOGS, TIMEZONE);
    expect(result).toBeUndefined();
  });

  it("returns the preferred hour's entry when it already has the best conditions", () => {
    // 3 PM is mild; 4 PM is hot
    const hourly = [
      makeHourly(`${DATE}T15:00:00-07:00`, { temperature_f: 70 }),
      makeHourly(`${DATE}T16:00:00-07:00`, { temperature_f: 100 }),
    ];
    const result = pickBestHourInWindow(hourly, DATE, 15, 14, 17, DOGS, TIMEZONE);
    expect(result?.local_timestamp).toContain("T15:");
  });

  it("returns a later hour when it has a less restrictive recommendation level", () => {
    // 3 PM is dangerously hot; 4 PM is mild — should prefer 4 PM
    const hourly = [
      makeHourly(`${DATE}T15:00:00-07:00`, { temperature_f: 105, feels_like_f: 110 }),
      makeHourly(`${DATE}T16:00:00-07:00`, { temperature_f: 70,  feels_like_f: 70  }),
    ];
    const result = pickBestHourInWindow(hourly, DATE, 15, 14, 17, DOGS, TIMEZONE);
    expect(result?.local_timestamp).toContain("T16:");
  });

  it("breaks ties by proximity to the preferred hour", () => {
    // 3 PM, 4 PM, and 5 PM all have mild conditions — preferred is 4 PM
    const hourly = [
      makeHourly(`${DATE}T15:00:00-07:00`, { temperature_f: 70 }),
      makeHourly(`${DATE}T16:00:00-07:00`, { temperature_f: 70 }),
      makeHourly(`${DATE}T17:00:00-07:00`, { temperature_f: 70 }),
    ];
    const result = pickBestHourInWindow(hourly, DATE, 16, 14, 17, DOGS, TIMEZONE);
    expect(result?.local_timestamp).toContain("T16:");
  });

  it("ignores entries from a different date", () => {
    const otherDate = "2026-07-16";
    const hourly = [
      makeHourly(`${otherDate}T15:00:00-07:00`, { temperature_f: 70 }),
    ];
    const result = pickBestHourInWindow(hourly, DATE, 15, 14, 17, DOGS, TIMEZONE);
    expect(result).toBeUndefined();
  });

  it("considers only entries within the window bounds", () => {
    // 1 PM is outside afternoon window (14–17); 3 PM is inside
    const hourly = [
      makeHourly(`${DATE}T13:00:00-07:00`, { temperature_f: 70 }),
      makeHourly(`${DATE}T15:00:00-07:00`, { temperature_f: 75 }),
    ];
    const result = pickBestHourInWindow(hourly, DATE, 15, 14, 17, DOGS, TIMEZONE);
    expect(result?.local_timestamp).toContain("T15:");
  });

  it("returns the single candidate when only one entry exists in the window", () => {
    const hourly = [
      makeHourly(`${DATE}T15:00:00-07:00`),
    ];
    const result = pickBestHourInWindow(hourly, DATE, 15, 14, 17, DOGS, TIMEZONE);
    expect(result?.local_timestamp).toContain("T15:");
  });
});
