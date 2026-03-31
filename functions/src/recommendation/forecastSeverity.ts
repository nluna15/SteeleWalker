import { RecommendationLevel as L, type HourlyEntry, type WeatherEntry } from "./types";

export enum ForecastSeverityBand {
  safe = "safe",
  caution = "caution",
  unsafe = "unsafe",
  unknown = "unknown",
}

export interface ForecastSeverityBands {
  temperature: ForecastSeverityBand;
  precipitation: ForecastSeverityBand;
  wind: ForecastSeverityBand;
  uv: ForecastSeverityBand;
  humidity: ForecastSeverityBand;
  airQuality: ForecastSeverityBand;
  storm: ForecastSeverityBand;
  pavement: ForecastSeverityBand;
}

const BAND_PRIORITY: Record<ForecastSeverityBand, number> = {
  [ForecastSeverityBand.safe]: 0,
  [ForecastSeverityBand.caution]: 1,
  [ForecastSeverityBand.unsafe]: 2,
  [ForecastSeverityBand.unknown]: -1,
};

export const HEAT_VERY_SHORT_WALK_MIN_F = 85;
export const HEAT_BATHROOM_ONLY_MIN_F = 90;
export const HEAT_DO_NOT_WALK_MIN_F = 95;

export const COLD_VERY_SHORT_WALK_MAX_F = 32;
export const COLD_BATHROOM_ONLY_MAX_F = 20;
export const COLD_DO_NOT_WALK_MAX_F = 0;

export const AQI_VERY_SHORT_WALK_MIN = 101;
export const AQI_BATHROOM_ONLY_MIN = 151;
export const AQI_DO_NOT_WALK_MIN = 201;

export const THUNDER_CODES = new Set([1087, 1273, 1276, 1279, 1282]);
export const SEVERE_THUNDER_CODES = new Set([1273, 1276, 1279, 1282]);
export const STORM_UNSAFE_WIND_MPH = 30;

export const PAVEMENT_VERY_SHORT_WALK_SURFACE_F = 135;
export const PAVEMENT_BATHROOM_ONLY_SURFACE_F = 150;

export const FREEZING_RAIN_UNSAFE_PROBABILITY = 60;
export const RAIN_CAUTION_PROBABILITY = 70;

export const WIND_CAUTION_MPH = 20;
export const WIND_UNSAFE_MPH = 30;

export const UV_CAUTION_INDEX = 8;
export const UV_UNSAFE_INDEX = 11;

export const HUMIDITY_TEMP_MIN_F = 75;
export const HUMIDITY_CAUTION_PERCENT = 70;
export const HUMIDITY_UNSAFE_PERCENT = 80;

function maxBand(
  left: ForecastSeverityBand,
  right: ForecastSeverityBand
): ForecastSeverityBand {
  return BAND_PRIORITY[left] >= BAND_PRIORITY[right] ? left : right;
}

export function heatRecommendationLevel(feelsLikeF: number): L | null {
  if (feelsLikeF >= HEAT_DO_NOT_WALK_MIN_F) return L.do_not_walk;
  if (feelsLikeF >= HEAT_BATHROOM_ONLY_MIN_F) return L.bathroom_only;
  if (feelsLikeF >= HEAT_VERY_SHORT_WALK_MIN_F) return L.very_short_walk;
  return null;
}

export function heatBand(feelsLikeF: number): ForecastSeverityBand {
  if (feelsLikeF >= HEAT_DO_NOT_WALK_MIN_F) return ForecastSeverityBand.unsafe;
  if (feelsLikeF >= HEAT_VERY_SHORT_WALK_MIN_F) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function windChill(tempF: number, windMph: number): number {
  if (windMph < 3 || tempF > 50) return tempF;
  return (
    35.74 +
    0.6215 * tempF -
    35.75 * Math.pow(windMph, 0.16) +
    0.4275 * tempF * Math.pow(windMph, 0.16)
  );
}

export function coldRecommendationLevel(
  temperatureF: number,
  windSpeedMph: number
): L | null {
  const effectiveTemp = windChill(temperatureF, windSpeedMph);
  if (effectiveTemp < COLD_DO_NOT_WALK_MAX_F) return L.do_not_walk;
  if (effectiveTemp < COLD_BATHROOM_ONLY_MAX_F) return L.bathroom_only;
  if (effectiveTemp < COLD_VERY_SHORT_WALK_MAX_F) return L.very_short_walk;
  return null;
}

export function coldBand(
  temperatureF: number,
  windSpeedMph: number
): ForecastSeverityBand {
  const effectiveTemp = windChill(temperatureF, windSpeedMph);
  if (effectiveTemp < COLD_DO_NOT_WALK_MAX_F) return ForecastSeverityBand.unsafe;
  if (effectiveTemp < COLD_VERY_SHORT_WALK_MAX_F) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function temperatureBand(weather: WeatherEntry | HourlyEntry): ForecastSeverityBand {
  return maxBand(
    heatBand(weather.feels_like_f),
    coldBand(weather.temperature_f, weather.wind_speed_mph)
  );
}

export function airQualityRecommendationLevel(aqi: number | null | undefined): L | null {
  if (aqi == null) return null;
  if (aqi >= AQI_DO_NOT_WALK_MIN) return L.do_not_walk;
  if (aqi >= AQI_BATHROOM_ONLY_MIN) return L.bathroom_only;
  if (aqi >= AQI_VERY_SHORT_WALK_MIN) return L.very_short_walk;
  return null;
}

export function airQualityBand(aqi: number | null | undefined): ForecastSeverityBand {
  if (aqi == null) return ForecastSeverityBand.unknown;
  if (aqi >= AQI_DO_NOT_WALK_MIN) return ForecastSeverityBand.unsafe;
  if (aqi >= AQI_VERY_SHORT_WALK_MIN) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function stormRecommendationLevel(
  weatherCode: number,
  windSpeedMph: number
): L | null {
  if (!THUNDER_CODES.has(weatherCode)) return null;
  if (SEVERE_THUNDER_CODES.has(weatherCode) && windSpeedMph > STORM_UNSAFE_WIND_MPH) {
    return L.do_not_walk;
  }
  return L.bathroom_only;
}

export function stormBand(
  weatherCode: number,
  windSpeedMph: number
): ForecastSeverityBand {
  if (!THUNDER_CODES.has(weatherCode)) return ForecastSeverityBand.safe;
  if (SEVERE_THUNDER_CODES.has(weatherCode) && windSpeedMph > STORM_UNSAFE_WIND_MPH) {
    return ForecastSeverityBand.unsafe;
  }
  return ForecastSeverityBand.caution;
}

export function estimateSurfaceTemp(
  airTempF: number,
  weatherCode: number,
  localTimestamp: string | undefined
): number {
  let solarMultiplier = 0;
  if (localTimestamp) {
    const match = localTimestamp.match(/T(\d{2}):/);
    if (match) {
      const hour = parseInt(match[1], 10);
      if (hour >= 10 && hour < 16) {
        solarMultiplier = 1.0;
      } else if ((hour >= 6 && hour < 10) || (hour >= 16 && hour < 20)) {
        solarMultiplier = 0.5;
      }
    }
  }

  let skyOffset: number;
  if (weatherCode === 1000 || weatherCode === 1003) {
    skyOffset = 40;
  } else if (weatherCode === 1006) {
    skyOffset = 30;
  } else {
    skyOffset = 15;
  }

  return airTempF + skyOffset * solarMultiplier;
}

export function pavementRecommendationLevel(
  airTempF: number,
  weatherCode: number,
  localTimestamp: string | undefined
): L | null {
  const surfaceTemp = estimateSurfaceTemp(airTempF, weatherCode, localTimestamp);
  if (surfaceTemp > PAVEMENT_BATHROOM_ONLY_SURFACE_F) return L.bathroom_only;
  if (surfaceTemp > PAVEMENT_VERY_SHORT_WALK_SURFACE_F) return L.very_short_walk;
  return null;
}

export function pavementBand(
  airTempF: number,
  weatherCode: number,
  localTimestamp: string | undefined
): ForecastSeverityBand {
  const surfaceTemp = estimateSurfaceTemp(airTempF, weatherCode, localTimestamp);
  if (surfaceTemp > PAVEMENT_BATHROOM_ONLY_SURFACE_F) return ForecastSeverityBand.unsafe;
  if (surfaceTemp > PAVEMENT_VERY_SHORT_WALK_SURFACE_F) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function hazardousPrecipRecommendationLevel(
  precipType: string | null,
  precipProbability: number
): L | null {
  if (precipType === "ice_pellets") return L.do_not_walk;
  if (
    precipType === "freezing_rain" &&
    precipProbability > FREEZING_RAIN_UNSAFE_PROBABILITY
  ) {
    return L.bathroom_only;
  }
  return null;
}

export function precipitationBand(
  precipProbability: number,
  precipType: string | null
): ForecastSeverityBand {
  if (precipType === "ice_pellets") return ForecastSeverityBand.unsafe;
  if (
    precipType === "freezing_rain" &&
    precipProbability > FREEZING_RAIN_UNSAFE_PROBABILITY
  ) {
    return ForecastSeverityBand.unsafe;
  }
  if (precipType === "rain" && precipProbability > RAIN_CAUTION_PROBABILITY) {
    return ForecastSeverityBand.caution;
  }
  return ForecastSeverityBand.safe;
}

export function windBand(windSpeedMph: number): ForecastSeverityBand {
  if (windSpeedMph > WIND_UNSAFE_MPH) return ForecastSeverityBand.unsafe;
  if (windSpeedMph >= WIND_CAUTION_MPH) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function uvBand(uvIndex: number): ForecastSeverityBand {
  if (uvIndex >= UV_UNSAFE_INDEX) return ForecastSeverityBand.unsafe;
  if (uvIndex >= UV_CAUTION_INDEX) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function humidityBand(
  humidity: number,
  temperatureF: number
): ForecastSeverityBand {
  if (temperatureF < HUMIDITY_TEMP_MIN_F) return ForecastSeverityBand.safe;
  if (humidity >= HUMIDITY_UNSAFE_PERCENT) return ForecastSeverityBand.unsafe;
  if (humidity >= HUMIDITY_CAUTION_PERCENT) return ForecastSeverityBand.caution;
  return ForecastSeverityBand.safe;
}

export function mapForecastSeverityBands(
  weather: WeatherEntry | HourlyEntry
): ForecastSeverityBands {
  const localTimestamp = "local_timestamp" in weather
    ? weather.local_timestamp
    : undefined;

  return {
    temperature: temperatureBand(weather),
    precipitation: precipitationBand(
      weather.precip_probability,
      weather.precip_type
    ),
    wind: windBand(weather.wind_speed_mph),
    uv: uvBand(weather.uv_index),
    humidity: humidityBand(weather.humidity, weather.temperature_f),
    airQuality: airQualityBand(weather.aqi),
    storm: stormBand(weather.weather_code, weather.wind_speed_mph),
    pavement: pavementBand(
      weather.temperature_f,
      weather.weather_code,
      localTimestamp
    ),
  };
}
