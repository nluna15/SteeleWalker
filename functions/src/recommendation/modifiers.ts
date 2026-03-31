import {
  RecommendationLevel as L,
  type DogRiskProfile,
  type WeatherEntry,
  type HourlyEntry,
} from "./types";
import {
  HUMIDITY_CAUTION_PERCENT,
  HUMIDITY_TEMP_MIN_F,
  HUMIDITY_UNSAFE_PERCENT,
  RAIN_CAUTION_PROBABILITY,
  UV_CAUTION_INDEX,
  UV_UNSAFE_INDEX,
  WIND_CAUTION_MPH,
  WIND_UNSAFE_MPH,
} from "./forecastSeverity";

export interface ModifiersResult {
  level: L;
  reasons: string[];
}

/**
 * Apply contextual modifiers that can only worsen the level (never improve).
 * Each modifier escalates by 1–2 steps from the current level.
 */
export function applyModifiers(
  startLevel: L,
  weather: WeatherEntry | HourlyEntry,
  profile: DogRiskProfile,
  humidityApplied: boolean
): ModifiersResult {
  let level = startLevel;
  const reasons: string[] = [];

  // 1. Rain
  if (
    weather.precip_probability > RAIN_CAUTION_PROBABILITY &&
    weather.precip_type === "rain"
  ) {
    level = Math.min(level + 1, L.do_not_walk) as L;
    reasons.push(`Rain likely (${weather.precip_probability}%)`);

    if (profile.sensitivities.includes("rain")) {
      level = Math.min(level + 1, L.do_not_walk) as L;
      reasons.push("Rain sensitivity");
    }
  }

  // 2. Wind
  const wind = weather.wind_speed_mph;
  if (wind > WIND_UNSAFE_MPH) {
    level = Math.min(level + 2, L.do_not_walk) as L;
    reasons.push(`High wind ${Math.round(wind)} mph`);
  } else if (wind >= WIND_CAUTION_MPH) {
    level = Math.min(level + 1, L.do_not_walk) as L;
    reasons.push(`Wind ${Math.round(wind)} mph`);
  }

  if (
    wind >= WIND_CAUTION_MPH &&
    (profile.size === "extra_small" || profile.size === "small")
  ) {
    level = Math.min(level + 1, L.do_not_walk) as L;
    reasons.push(`${profile.size} size in wind`);
  }

  // 3. UV
  const uv = weather.uv_index;
  if (uv >= UV_UNSAFE_INDEX) {
    const newLevel = Math.min(level + 2, L.short_walk, L.do_not_walk) as L;
    if (newLevel > level) { level = newLevel; reasons.push(`Extreme UV index ${uv}`); }
  } else if (uv >= UV_CAUTION_INDEX) {
    const newLevel = Math.min(level + 1, L.short_walk, L.do_not_walk) as L;
    if (newLevel > level) { level = newLevel; reasons.push(`Very high UV index ${uv}`); }
  }

  if (
    uv >= UV_CAUTION_INDEX - 2 &&
    (profile.coatCategory === "short" || profile.coatCategory === "hairless")
  ) {
    const cappedCoatUv = Math.min(level + 1, L.short_walk) as L;
    if (cappedCoatUv > level) {
      level = cappedCoatUv;
      reasons.push(`${profile.coatCategory} coat UV exposure`);
    }
  }

  // 4. Humidity (only if not already applied by heat hard stop)
  if (!humidityApplied) {
    const h = weather.humidity;
    const t = weather.temperature_f;
    if (h >= HUMIDITY_UNSAFE_PERCENT && t >= HUMIDITY_TEMP_MIN_F) {
      level = Math.min(level + 2, L.do_not_walk) as L;
      reasons.push(`High humidity ${h}% at ${t}°F`);
    } else if (h >= HUMIDITY_CAUTION_PERCENT && t >= HUMIDITY_TEMP_MIN_F) {
      level = Math.min(level + 1, L.do_not_walk) as L;
      reasons.push(`Humidity ${h}% at ${t}°F`);
    }
  }

  return { level, reasons };
}
