import { evaluateForDog, evaluateHousehold } from "../engine";
import { RecommendationLevel as L, levelToKey } from "../types";
import type { FirestoreDog, WeatherEntry, HourlyEntry } from "../types";

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
    uv_index: 4,
    aqi: null,
    wind_direction_deg: 180,
    captured_at: "2026-07-15T19:00:00Z",
    ...overrides,
  };
}

function makeHourly(
  localTimestamp: string,
  overrides: Partial<WeatherEntry> = {}
): HourlyEntry {
  return {
    ...baseWeather(overrides),
    local_timestamp: localTimestamp,
  };
}

const TIMEZONE = "America/Los_Angeles";

// ---------------------------------------------------------------------------
// evaluateForDog — basic flow
// ---------------------------------------------------------------------------
describe("evaluateForDog", () => {
  it("returns optimal for healthy dog in mild weather", () => {
    const result = evaluateForDog(
      baseDog(),
      baseWeather(),
      [makeHourly("2026-07-15T13:00:00-07:00")],
      TIMEZONE
    );

    expect(result.dogId).toBe("dog-1");
    expect(result.dogName).toBe("Buddy");
    expect(result.current.level).toBe(L.optimal);
    expect(result.current.levelKey).toBe("optimal");
    expect(result.hourly).toHaveLength(1);
  });

  it("populates reasons for heat hard stop", () => {
    const result = evaluateForDog(
      baseDog(),
      baseWeather({ feels_like_f: 90 }),
      [],
      TIMEZONE
    );

    expect(result.current.level).toBe(L.bathroom_only);
    expect(result.current.hardStopReasons.length).toBeGreaterThan(0);
    expect(result.current.reasons.join(" ")).toContain("Heat");
  });

  // -----------------------------------------------------------------------
  // AQI carry-forward
  // -----------------------------------------------------------------------
  describe("AQI carry-forward", () => {
    it("copies current.aqi to hourly entries where aqi is null", () => {
      const result = evaluateForDog(
        baseDog({ health_conditions: ["breathing_difficulty"] }),
        baseWeather({ aqi: 160 }), // bathroom_only for breathing
        [
          makeHourly("2026-07-15T14:00:00-07:00", { aqi: null }),
          makeHourly("2026-07-15T15:00:00-07:00", { aqi: null }),
        ],
        TIMEZONE
      );

      // Current AQI 160 → bathroom_only for breathing dog
      expect(result.current.level).toBeGreaterThanOrEqual(L.bathroom_only);

      // Hourly entries should also reflect AQI risk (carried forward)
      for (const h of result.hourly) {
        expect(h.reasons.join(" ")).toContain("Air quality");
      }
    });

    it("does not overwrite hourly aqi when it has its own value", () => {
      const result = evaluateForDog(
        baseDog(),
        baseWeather({ aqi: 200 }), // high current AQI
        [makeHourly("2026-07-15T14:00:00-07:00", { aqi: 50 })], // low hourly AQI
        TIMEZONE
      );

      // Hourly AQI 50 → no AQI trigger
      const hourlyReasons = result.hourly[0].reasons.join(" ");
      expect(hourlyReasons).not.toContain("Air quality");
    });

    it("does not carry forward when current.aqi is null", () => {
      const result = evaluateForDog(
        baseDog(),
        baseWeather({ aqi: null }),
        [makeHourly("2026-07-15T14:00:00-07:00", { aqi: null })],
        TIMEZONE
      );

      const hourlyReasons = result.hourly[0].reasons.join(" ");
      expect(hourlyReasons).not.toContain("Air quality");
    });
  });

  // -----------------------------------------------------------------------
  // Timezone-aware current evaluation
  // -----------------------------------------------------------------------
  it("uses timezone for pavement burn on current weather", () => {
    // captured_at 7 PM UTC = noon PDT in summer. 120°F + clear sky peak (40) = 160°F
    const result = evaluateForDog(
      baseDog(),
      baseWeather({
        temperature_f: 120,
        feels_like_f: 72, // avoid heat trigger
        captured_at: "2026-07-15T19:00:00Z",
        weather_code: 1000,
      }),
      [],
      "America/Los_Angeles"
    );

    // Pavement should trigger (120 + 40 = 160 > 150 → bathroom_only)
    expect(result.current.level).toBeGreaterThanOrEqual(L.bathroom_only);
    expect(result.current.reasons.join(" ")).toContain("Pavement");
  });
});

// ---------------------------------------------------------------------------
// evaluateHousehold — most restrictive aggregation
// ---------------------------------------------------------------------------
describe("evaluateHousehold", () => {
  it("picks the most restrictive current level across dogs", () => {
    const dog1 = evaluateForDog(
      baseDog({ id: "d1", name: "Max" }),
      baseWeather(), // optimal
      [makeHourly("2026-07-15T14:00:00-07:00")],
      TIMEZONE
    );
    const dog2 = evaluateForDog(
      baseDog({ id: "d2", name: "Rex", health_conditions: ["breathing_difficulty"] }),
      baseWeather({ feels_like_f: 90 }), // bathroom_only+
      [makeHourly("2026-07-15T14:00:00-07:00", { feels_like_f: 90 })],
      TIMEZONE
    );

    const household = evaluateHousehold([dog1, dog2]);
    expect(household.current.level).toBeGreaterThanOrEqual(L.bathroom_only);
    expect(household.current.levelKey).toBe(levelToKey(household.current.level as L));
  });

  it("picks the most restrictive hourly level per slot", () => {
    const mild = makeHourly("2026-07-15T14:00:00-07:00");
    const hot = makeHourly("2026-07-15T14:00:00-07:00", { feels_like_f: 95 });

    const dog1 = evaluateForDog(
      baseDog({ id: "d1", name: "Max" }),
      baseWeather(),
      [mild],
      TIMEZONE
    );
    const dog2 = evaluateForDog(
      baseDog({ id: "d2", name: "Rex" }),
      baseWeather(),
      [hot],
      TIMEZONE
    );

    const household = evaluateHousehold([dog1, dog2]);
    expect(household.hourly[0].level).toBe(L.do_not_walk);
  });

  it("deduplicates reasons across dogs", () => {
    // Two identical dogs in identical weather → same reasons, should deduplicate
    const dog1 = evaluateForDog(
      baseDog({ id: "d1", name: "Max" }),
      baseWeather({ feels_like_f: 85 }),
      [],
      TIMEZONE
    );
    const dog2 = evaluateForDog(
      baseDog({ id: "d2", name: "Rex" }),
      baseWeather({ feels_like_f: 85 }),
      [],
      TIMEZONE
    );

    const household = evaluateHousehold([dog1, dog2]);
    const uniqueReasons = new Set(household.current.reasons);
    expect(household.current.reasons.length).toBe(uniqueReasons.size);
  });

  it("throws for empty dog results", () => {
    expect(() => evaluateHousehold([])).toThrow("At least one dog result");
  });
});

// ---------------------------------------------------------------------------
// levelToKey mapping
// ---------------------------------------------------------------------------
describe("levelToKey", () => {
  const cases: [L, string][] = [
    [L.optimal, "optimal"],
    [L.normal_walk, "normal_walk"],
    [L.short_walk, "short_walk"],
    [L.very_short_walk, "very_short_walk"],
    [L.bathroom_only, "bathroom_only"],
    [L.do_not_walk, "do_not_walk"],
  ];

  test.each(cases)("level %i → %s", (level, expected) => {
    expect(levelToKey(level)).toBe(expected);
  });
});
