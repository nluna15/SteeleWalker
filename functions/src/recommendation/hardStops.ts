import {
  RecommendationLevel as L,
  type DogRiskProfile,
  type HardStopResult,
  type WeatherEntry,
  type HourlyEntry,
} from "./types";
import {
  airQualityRecommendationLevel,
  coldRecommendationLevel,
  estimateSurfaceTemp,
  hazardousPrecipRecommendationLevel,
  heatRecommendationLevel,
  pavementRecommendationLevel,
  stormRecommendationLevel,
  windChill,
} from "./forecastSeverity";

type Evaluator = (
  weather: WeatherEntry | HourlyEntry,
  profile: DogRiskProfile
) => HardStopResult;

/** Clamp an escalation so it doesn't exceed `maxSteps` above `base`. */
function escalate(
  base: L,
  steps: number,
  maxSteps: number = 2
): L {
  return Math.min(base + steps, base + maxSteps, L.do_not_walk) as L;
}

// ---------------------------------------------------------------------------
// 1. Heat
// ---------------------------------------------------------------------------
const evaluateHeat: Evaluator = (weather, profile) => {
  const f = weather.feels_like_f;
  let ceiling = heatRecommendationLevel(f);
  let humidityApplied = false;

  if (ceiling === null) return { ceiling: null, reason: "", evaluator: "heat", humidityApplied: false };

  // Escalations (capped at 2 total steps)
  let steps = 0;
  const reasons: string[] = [`Feels-like ${f}°F`];

  if (profile.hasBreathingIssue) { steps++; reasons.push("breathing issues"); }
  if (profile.hasHeartCondition) { steps++; reasons.push("heart condition"); }
  if (steps < 2 && (profile.ageBand === "senior" || profile.ageBand === "puppy")) {
    steps++; reasons.push(profile.ageBand);
  }
  if (steps < 2 && profile.sensitivities.includes("extreme_heat")) {
    steps++; reasons.push("heat sensitivity");
  }
  if (steps < 2 && weather.humidity >= 70) {
    steps++; humidityApplied = true; reasons.push(`humidity ${weather.humidity}%`);
  }
  // Breed safety-nets (only if no condition already applied for breathing/heat)
  if (steps < 2 && profile.isBrachycephalic && !profile.hasBreathingIssue) {
    steps++; reasons.push("brachycephalic breed");
  }
  if (steps < 2 && profile.coatCategory === "double" && !profile.sensitivities.includes("extreme_heat")) {
    steps++; reasons.push("double coat");
  }

  ceiling = escalate(ceiling, steps);

  return {
    ceiling,
    reason: `Heat risk: ${reasons.join(", ")}`,
    evaluator: "heat",
    humidityApplied,
  };
};

// ---------------------------------------------------------------------------
// 2. Cold
// ---------------------------------------------------------------------------
const evaluateCold: Evaluator = (weather, profile) => {
  const effectiveTemp = windChill(weather.temperature_f, weather.wind_speed_mph);
  let ceiling = coldRecommendationLevel(
    weather.temperature_f,
    weather.wind_speed_mph
  );

  if (ceiling === null) return { ceiling: null, reason: "", evaluator: "cold", humidityApplied: false };

  let steps = 0;
  const reasons: string[] = [`Effective temp ${Math.round(effectiveTemp)}°F`];

  if (profile.size === "extra_small" || profile.size === "small") {
    steps++; reasons.push(`${profile.size} size`);
  }
  if (steps < 2 && profile.ageBand === "puppy") { steps++; reasons.push("puppy"); }
  if (steps < 2 && profile.ageBand === "senior") { steps++; reasons.push("senior"); }
  if (steps < 2 && profile.hasMobilityIssue) { steps++; reasons.push("mobility issues"); }
  if (steps < 2 && profile.sensitivities.includes("extreme_cold")) {
    steps++; reasons.push("cold sensitivity");
  }

  ceiling = escalate(ceiling, steps);

  // De-escalation: double coat improves 1 step (min optimal)
  if (profile.coatCategory === "double" && ceiling > L.optimal) {
    ceiling = (ceiling - 1) as L;
    reasons.push("double coat (de-escalation)");
  }

  return {
    ceiling,
    reason: `Cold risk: ${reasons.join(", ")}`,
    evaluator: "cold",
    humidityApplied: false,
  };
};

// ---------------------------------------------------------------------------
// 3. AQI
// ---------------------------------------------------------------------------
const evaluateAqi: Evaluator = (weather, profile) => {
  const aqi = weather.aqi;
  let ceiling = airQualityRecommendationLevel(aqi);
  if (ceiling === null) {
    return { ceiling: null, reason: "", evaluator: "aqi", humidityApplied: false };
  }

  let steps = 0;
  const reasons: string[] = [`AQI ${aqi}`];

  if (profile.hasBreathingIssue) { steps++; reasons.push("breathing issues"); }
  if (steps < 2 && profile.hasHeartCondition) { steps++; reasons.push("heart condition"); }
  if (steps < 2 && (profile.ageBand === "senior" || profile.ageBand === "puppy")) {
    steps++; reasons.push(profile.ageBand);
  }

  ceiling = escalate(ceiling, steps);

  return {
    ceiling,
    reason: `Air quality: ${reasons.join(", ")}`,
    evaluator: "aqi",
    humidityApplied: false,
  };
};

// ---------------------------------------------------------------------------
// 4. Storm
// ---------------------------------------------------------------------------
const evaluateStorm: Evaluator = (weather, profile) => {
  let ceiling = stormRecommendationLevel(
    weather.weather_code,
    weather.wind_speed_mph
  );
  if (ceiling === null) {
    return { ceiling: null, reason: "", evaluator: "storm", humidityApplied: false };
  }

  const reasons: string[] = ["Thunderstorm activity"];
  if (ceiling === L.do_not_walk) {
    reasons.push(`wind ${Math.round(weather.wind_speed_mph)} mph`);
  }

  if (profile.sensitivities.includes("thunder_lightning")) {
    ceiling = L.do_not_walk; // No cap — direct to do_not_walk
    reasons.push("thunder/lightning sensitivity");
  }

  return {
    ceiling,
    reason: `Storm: ${reasons.join(", ")}`,
    evaluator: "storm",
    humidityApplied: false,
  };
};

// ---------------------------------------------------------------------------
// 5. Pavement burn
// ---------------------------------------------------------------------------

const evaluatePavement: Evaluator = (weather, profile) => {
  // Hourly entries have local_timestamp; for current weather the engine
  // pre-computes and attaches a local_timestamp before calling evaluators.
  const localTs = "local_timestamp" in weather
    ? (weather as HourlyEntry).local_timestamp
    : undefined;

  const surfaceTemp = estimateSurfaceTemp(
    weather.temperature_f,
    weather.weather_code,
    localTs
  );

  const ceiling = pavementRecommendationLevel(
    weather.temperature_f,
    weather.weather_code,
    localTs
  );

  if (ceiling === null) return { ceiling: null, reason: "", evaluator: "pavement", humidityApplied: false };

  return {
    ceiling,
    reason: `Pavement burn risk: estimated surface ${Math.round(surfaceTemp)}°F`,
    evaluator: "pavement",
    humidityApplied: false,
  };
};

// ---------------------------------------------------------------------------
// 6. Hazardous precipitation
// ---------------------------------------------------------------------------
const evaluateHazardousPrecip: Evaluator = (weather, profile) => {
  const ceiling = hazardousPrecipRecommendationLevel(
    weather.precip_type,
    weather.precip_probability
  );
  if (ceiling === L.bathroom_only) {
    return {
      ceiling,
      reason: `Hazardous precipitation: freezing rain (${weather.precip_probability}% probability)`,
      evaluator: "hazardous_precip",
      humidityApplied: false,
    };
  }
  if (ceiling === L.do_not_walk) {
    return {
      ceiling,
      reason: "Hazardous precipitation: ice pellets",
      evaluator: "hazardous_precip",
      humidityApplied: false,
    };
  }

  return { ceiling: null, reason: "", evaluator: "hazardous_precip", humidityApplied: false };
};

// ---------------------------------------------------------------------------
// Aggregate
// ---------------------------------------------------------------------------
const ALL_EVALUATORS: Evaluator[] = [
  evaluateHeat,
  evaluateCold,
  evaluateAqi,
  evaluateStorm,
  evaluatePavement,
  evaluateHazardousPrecip,
];

export interface HardStopsResult {
  ceiling: L;
  reasons: string[];
  humidityApplied: boolean;
}

/**
 * Run all hard-stop evaluators and return the most restrictive ceiling.
 */
export function evaluateHardStops(
  weather: WeatherEntry | HourlyEntry,
  profile: DogRiskProfile
): HardStopsResult {
  let ceiling = L.optimal;
  const reasons: string[] = [];
  let humidityApplied = false;

  for (const evaluator of ALL_EVALUATORS) {
    const result = evaluator(weather, profile);
    if (result.ceiling !== null && result.ceiling > ceiling) {
      ceiling = result.ceiling;
    }
    if (result.reason) {
      reasons.push(result.reason);
    }
    if (result.humidityApplied) {
      humidityApplied = true;
    }
  }

  return { ceiling, reasons, humidityApplied };
}
