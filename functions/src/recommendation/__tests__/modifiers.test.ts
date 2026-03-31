import { applyModifiers } from "../modifiers";
import { RecommendationLevel as L } from "../types";
import type { DogRiskProfile, WeatherEntry } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Rain
// ---------------------------------------------------------------------------
describe("rain modifier", () => {
  it("does not escalate at exactly 70% precip probability", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ precip_probability: 70, precip_type: "rain" }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.optimal);
  });

  it("escalates +1 when rain >70%", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ precip_probability: 80, precip_type: "rain" }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.normal_walk);
  });

  it("escalates +2 with rain sensitivity", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ precip_probability: 80, precip_type: "rain" }),
      baseProfile({ sensitivities: ["rain"] }),
      false
    );
    expect(r.level).toBe(L.short_walk);
  });

  it("does not trigger for snow precip type", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ precip_probability: 90, precip_type: "snow" }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.optimal);
  });
});

// ---------------------------------------------------------------------------
// Wind
// ---------------------------------------------------------------------------
describe("wind modifier", () => {
  it("does not escalate below 20 mph", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ wind_speed_mph: 19 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.optimal);
  });

  it("escalates +1 at 20 mph", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ wind_speed_mph: 20 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.normal_walk);
  });

  it("escalates +2 above 30 mph", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ wind_speed_mph: 35 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.short_walk);
  });

  it("adds +1 for extra_small dogs in wind >= 20", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ wind_speed_mph: 25 }),
      baseProfile({ size: "extra_small" }),
      false
    );
    // +1 wind + 1 size = +2
    expect(r.level).toBe(L.short_walk);
  });
});

// ---------------------------------------------------------------------------
// UV — capped at short_walk
// ---------------------------------------------------------------------------
describe("UV modifier", () => {
  it("escalates +1 at UV 8", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ uv_index: 8 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.normal_walk);
  });

  it("escalates +2 at UV 11 but caps at short_walk", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ uv_index: 11 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.short_walk);
  });

  it("does not push beyond short_walk even for hairless coat UV", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ uv_index: 11 }),
      baseProfile({ coatCategory: "hairless" }),
      false
    );
    // UV base → short_walk (2). Coat UV capped at short_walk → still 2
    expect(r.level).toBe(L.short_walk);
  });

  it("hairless coat escalates at UV 6 when below short_walk", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ uv_index: 6 }),
      baseProfile({ coatCategory: "hairless" }),
      false
    );
    // UV 6 < 8 → no base UV escalation. Coat UV 6: +1 capped at short_walk → normal_walk
    expect(r.level).toBe(L.normal_walk);
  });

  it("coat UV does not apply to medium coat dogs", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ uv_index: 7 }),
      baseProfile({ coatCategory: "medium" }),
      false
    );
    expect(r.level).toBe(L.optimal);
  });
});

// ---------------------------------------------------------------------------
// Humidity — double-counting prevention
// ---------------------------------------------------------------------------
describe("humidity modifier", () => {
  it("escalates +1 when humidity >= 70 and temp >= 75 and humidityApplied=false", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ humidity: 70, temperature_f: 75 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.normal_walk);
  });

  it("escalates +2 when humidity >= 80 and temp >= 75", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ humidity: 85, temperature_f: 80 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.short_walk);
  });

  it("skips humidity when humidityApplied=true (already counted by heat)", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ humidity: 85, temperature_f: 80 }),
      baseProfile(),
      true // already applied
    );
    expect(r.level).toBe(L.optimal);
  });

  it("does not escalate when temp < 75 even with high humidity", () => {
    const r = applyModifiers(
      L.optimal,
      baseWeather({ humidity: 90, temperature_f: 74 }),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.optimal);
  });
});

// ---------------------------------------------------------------------------
// Modifiers never improve level
// ---------------------------------------------------------------------------
describe("modifiers never improve level", () => {
  it("starting at very_short_walk with no triggers stays at very_short_walk", () => {
    const r = applyModifiers(
      L.very_short_walk,
      baseWeather(),
      baseProfile(),
      false
    );
    expect(r.level).toBe(L.very_short_walk);
  });

  it("capped at do_not_walk", () => {
    const r = applyModifiers(
      L.bathroom_only,
      baseWeather({ wind_speed_mph: 35, precip_probability: 90, precip_type: "rain" }),
      baseProfile({ sensitivities: ["rain"] }),
      false
    );
    expect(r.level).toBe(L.do_not_walk);
  });
});
