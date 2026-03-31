import { evaluateHardStops } from "../hardStops";
import { RecommendationLevel as L } from "../types";
import type { DogRiskProfile, WeatherEntry, HourlyEntry } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Healthy adult medium-coat dog with no conditions or sensitivities. */
function baseProfile(overrides: Partial<DogRiskProfile> = {}): DogRiskProfile {
  return {
    ageBand: "adult",
    size: "medium",
    healthConditions: [],
    sensitivities: [],
    isBrachycephalic: false,
    coatCategory: "medium",
    hasMobilityIssue: false,
    hasBreathingIssue: false,
    hasHeartCondition: false,
    ...overrides,
  };
}

/** Mild, safe weather baseline — should produce `optimal`. */
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

/** Hourly entry with local_timestamp for pavement tests. */
function hourlyWeather(
  localTimestamp: string,
  overrides: Partial<WeatherEntry> = {}
): HourlyEntry {
  return {
    ...baseWeather(overrides),
    local_timestamp: localTimestamp,
  };
}

// ---------------------------------------------------------------------------
// 1. Heat — threshold boundaries
// ---------------------------------------------------------------------------
describe("heat hard stop", () => {
  it("returns optimal below 85°F feels-like", () => {
    const r = evaluateHardStops(baseWeather({ feels_like_f: 84.9 }), baseProfile());
    expect(r.ceiling).toBe(L.optimal);
  });

  it("returns very_short_walk at exactly 85°F", () => {
    const r = evaluateHardStops(baseWeather({ feels_like_f: 85 }), baseProfile());
    expect(r.ceiling).toBe(L.very_short_walk);
  });

  it("returns bathroom_only at 90°F", () => {
    const r = evaluateHardStops(baseWeather({ feels_like_f: 90 }), baseProfile());
    expect(r.ceiling).toBe(L.bathroom_only);
  });

  it("returns do_not_walk at 95°F", () => {
    const r = evaluateHardStops(baseWeather({ feels_like_f: 95 }), baseProfile());
    expect(r.ceiling).toBe(L.do_not_walk);
  });

  it("caps escalation at 2 steps above base", () => {
    // 85°F → very_short_walk (3). With breathing + heart → +2 → do_not_walk (5)
    const profile = baseProfile({
      hasBreathingIssue: true,
      hasHeartCondition: true,
      ageBand: "senior", // would be +1 more, but cap is 2
    });
    const r = evaluateHardStops(baseWeather({ feels_like_f: 85 }), profile);
    expect(r.ceiling).toBe(L.do_not_walk); // 3 + 2 = 5
  });

  it("sets humidityApplied when humidity >= 70 escalates heat", () => {
    // 85°F base → very_short_walk. Humidity 75% → +1 step
    const r = evaluateHardStops(
      baseWeather({ feels_like_f: 85, humidity: 75 }),
      baseProfile()
    );
    expect(r.humidityApplied).toBe(true);
    expect(r.ceiling).toBe(L.bathroom_only); // 3 + 1 = 4
  });

  it("does not set humidityApplied when humidity < 70", () => {
    const r = evaluateHardStops(
      baseWeather({ feels_like_f: 85, humidity: 65 }),
      baseProfile()
    );
    expect(r.humidityApplied).toBe(false);
  });

  it("brachycephalic escalates only if no breathing issue already counted", () => {
    // With breathing issue: +1 from breathing, brachycephalic skipped (redundant)
    const withBreathing = baseProfile({
      isBrachycephalic: true,
      hasBreathingIssue: true,
    });
    const r1 = evaluateHardStops(baseWeather({ feels_like_f: 85 }), withBreathing);

    // Without breathing issue: brachycephalic contributes +1
    const withoutBreathing = baseProfile({
      isBrachycephalic: true,
      hasBreathingIssue: false,
    });
    const r2 = evaluateHardStops(baseWeather({ feels_like_f: 85 }), withoutBreathing);

    // Both should escalate by 1 total — same result
    expect(r1.ceiling).toBe(L.bathroom_only);
    expect(r2.ceiling).toBe(L.bathroom_only);
  });
});

// ---------------------------------------------------------------------------
// 2. Cold — wind chill + double-coat de-escalation
// ---------------------------------------------------------------------------
describe("cold hard stop", () => {
  it("returns optimal at 32°F with low wind", () => {
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 32, feels_like_f: 32, wind_speed_mph: 2 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });

  it("returns very_short_walk at 25°F (no wind chill)", () => {
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 25, feels_like_f: 25, wind_speed_mph: 2 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.very_short_walk);
  });

  it("applies NWS wind chill when wind >= 3 mph and temp <= 50°F", () => {
    // 30°F with 15 mph wind → wind chill ≈ 19°F → bathroom_only
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 30, feels_like_f: 30, wind_speed_mph: 15 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.bathroom_only);
  });

  it("does not apply wind chill when temp > 50°F", () => {
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 55, feels_like_f: 55, wind_speed_mph: 20 }),
      baseProfile()
    );
    // 55°F with wind → no wind chill applied → still above 32 → optimal
    expect(r.ceiling).toBe(L.optimal);
  });

  it("de-escalates 1 step for double-coat breeds", () => {
    // 25°F → very_short_walk (3). Double coat → 3 - 1 = 2 (short_walk)
    const profile = baseProfile({ coatCategory: "double" });
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 25, feels_like_f: 25, wind_speed_mph: 2 }),
      profile
    );
    expect(r.ceiling).toBe(L.short_walk);
  });

  it("de-escalation happens after escalation", () => {
    // 25°F → very_short_walk (3). Small dog → +1 = 4. Double coat → 4 - 1 = 3
    const profile = baseProfile({ coatCategory: "double", size: "small" });
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 25, feels_like_f: 25, wind_speed_mph: 2 }),
      profile
    );
    expect(r.ceiling).toBe(L.very_short_walk); // 3 + 1 - 1 = 3
  });

  it("do_not_walk at sub-zero effective temp", () => {
    const r = evaluateHardStops(
      baseWeather({ temperature_f: -5, feels_like_f: -5, wind_speed_mph: 2 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.do_not_walk);
  });

  it("escalates for extra_small size in cold", () => {
    // 25°F → very_short_walk. XS → +1 = bathroom_only
    const r = evaluateHardStops(
      baseWeather({ temperature_f: 25, feels_like_f: 25, wind_speed_mph: 2 }),
      baseProfile({ size: "extra_small" })
    );
    expect(r.ceiling).toBe(L.bathroom_only);
  });
});

// ---------------------------------------------------------------------------
// 3. AQI
// ---------------------------------------------------------------------------
describe("AQI hard stop", () => {
  it("returns optimal when aqi is null", () => {
    const r = evaluateHardStops(baseWeather({ aqi: null }), baseProfile());
    expect(r.ceiling).toBe(L.optimal);
  });

  it("returns optimal at AQI 100", () => {
    const r = evaluateHardStops(baseWeather({ aqi: 100 }), baseProfile());
    expect(r.ceiling).toBe(L.optimal);
  });

  it("returns very_short_walk at AQI 101", () => {
    const r = evaluateHardStops(baseWeather({ aqi: 101 }), baseProfile());
    expect(r.ceiling).toBe(L.very_short_walk);
  });

  it("returns bathroom_only at AQI 151", () => {
    const r = evaluateHardStops(baseWeather({ aqi: 151 }), baseProfile());
    expect(r.ceiling).toBe(L.bathroom_only);
  });

  it("returns do_not_walk at AQI 201", () => {
    const r = evaluateHardStops(baseWeather({ aqi: 201 }), baseProfile());
    expect(r.ceiling).toBe(L.do_not_walk);
  });

  it("escalates for breathing issues + senior", () => {
    // AQI 101 → very_short_walk (3). Breathing +1, senior +1 → do_not_walk (5)
    const profile = baseProfile({
      hasBreathingIssue: true,
      ageBand: "senior",
    });
    const r = evaluateHardStops(baseWeather({ aqi: 101 }), profile);
    expect(r.ceiling).toBe(L.do_not_walk);
  });
});

// ---------------------------------------------------------------------------
// 4. Storm
// ---------------------------------------------------------------------------
describe("storm hard stop", () => {
  it("returns optimal for non-thunder weather codes", () => {
    const r = evaluateHardStops(
      baseWeather({ weather_code: 1009 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });

  it("returns bathroom_only for thunder code 1087", () => {
    const r = evaluateHardStops(
      baseWeather({ weather_code: 1087 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.bathroom_only);
  });

  it("returns do_not_walk with thunder_lightning sensitivity (no cap)", () => {
    const profile = baseProfile({
      sensitivities: ["thunder_lightning"],
    });
    const r = evaluateHardStops(
      baseWeather({ weather_code: 1273 }),
      profile
    );
    expect(r.ceiling).toBe(L.do_not_walk);
  });

  it("returns do_not_walk for severe thunder codes with wind above 30 mph", () => {
    const r = evaluateHardStops(
      baseWeather({ weather_code: 1276, wind_speed_mph: 35 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.do_not_walk);
  });
});

// ---------------------------------------------------------------------------
// 5. Pavement burn — solar multiplier + sky offsets
// ---------------------------------------------------------------------------
describe("pavement burn hard stop", () => {
  it("triggers very_short_walk at peak sun with clear sky and hot air", () => {
    // 100°F air + clear sky peak (40) = 140°F surface → >135 → very_short_walk
    const r = evaluateHardStops(
      hourlyWeather("2026-07-15T13:00:00-07:00", {
        temperature_f: 100,
        feels_like_f: 80, // feels_like low enough to not trigger heat
        weather_code: 1000,
      }),
      baseProfile()
    );
    expect(r.ceiling).toBeGreaterThanOrEqual(L.very_short_walk);
  });

  it("triggers bathroom_only when surface > 150°F", () => {
    // 115°F + clear sky peak (40) = 155°F → bathroom_only
    const r = evaluateHardStops(
      hourlyWeather("2026-07-15T12:00:00-07:00", {
        temperature_f: 115,
        feels_like_f: 80,
        weather_code: 1000,
      }),
      baseProfile()
    );
    // Pavement contributes bathroom_only; heat may contribute more
    expect(r.ceiling).toBeGreaterThanOrEqual(L.bathroom_only);
  });

  it("does not trigger at night (solar multiplier = 0)", () => {
    // 100°F + clear sky night (0) = 100°F → no trigger
    const r = evaluateHardStops(
      hourlyWeather("2026-07-15T22:00:00-07:00", {
        temperature_f: 100,
        feels_like_f: 72, // no heat trigger
        weather_code: 1000,
      }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });

  it("uses half solar offset during shoulder hours", () => {
    // 100°F + clear sky shoulder (40 * 0.5 = 20) = 120°F → no trigger (< 135)
    const r = evaluateHardStops(
      hourlyWeather("2026-07-15T07:00:00-07:00", {
        temperature_f: 100,
        feels_like_f: 72,
        weather_code: 1000,
      }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });

  it("reduces sky offset for overcast conditions", () => {
    // 110°F + overcast peak (15) = 125°F → no trigger (< 135)
    const r = evaluateHardStops(
      hourlyWeather("2026-07-15T13:00:00-07:00", {
        temperature_f: 110,
        feels_like_f: 72,
        weather_code: 1009,
      }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });
});

// ---------------------------------------------------------------------------
// 6. Hazardous precipitation
// ---------------------------------------------------------------------------
describe("hazardous precipitation hard stop", () => {
  it("returns do_not_walk for ice pellets", () => {
    const r = evaluateHardStops(
      baseWeather({ precip_type: "ice_pellets" }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.do_not_walk);
  });

  it("returns bathroom_only for freezing rain with >60% probability", () => {
    const r = evaluateHardStops(
      baseWeather({ precip_type: "freezing_rain", precip_probability: 70 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.bathroom_only);
  });

  it("does not trigger for freezing rain at exactly 60% probability", () => {
    const r = evaluateHardStops(
      baseWeather({ precip_type: "freezing_rain", precip_probability: 60 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });

  it("does not trigger for regular rain", () => {
    const r = evaluateHardStops(
      baseWeather({ precip_type: "rain", precip_probability: 90 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.optimal);
  });
});

// ---------------------------------------------------------------------------
// 7. Aggregate — most restrictive wins
// ---------------------------------------------------------------------------
describe("evaluateHardStops aggregate", () => {
  it("picks the most restrictive ceiling across evaluators", () => {
    // AQI 201 → do_not_walk, heat 85°F → very_short_walk
    // Result: do_not_walk (most restrictive)
    const r = evaluateHardStops(
      baseWeather({ aqi: 201, feels_like_f: 85 }),
      baseProfile()
    );
    expect(r.ceiling).toBe(L.do_not_walk);
  });

  it("collects reasons from all triggering evaluators", () => {
    const r = evaluateHardStops(
      baseWeather({ aqi: 101, feels_like_f: 85 }),
      baseProfile()
    );
    const reasonText = r.reasons.join(" ");
    expect(reasonText).toContain("Heat risk");
    expect(reasonText).toContain("Air quality");
  });
});
