import {
  ForecastSeverityBand as Band,
  airQualityBand,
  coldBand,
  heatBand,
  humidityBand,
  mapForecastSeverityBands,
  pavementBand,
  precipitationBand,
  stormBand,
  temperatureBand,
  uvBand,
  windBand,
} from "../forecastSeverity";
import type { HourlyEntry, WeatherEntry } from "../types";

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

function hourlyWeather(
  localTimestamp: string,
  overrides: Partial<WeatherEntry> = {}
): HourlyEntry {
  return {
    ...baseWeather(overrides),
    local_timestamp: localTimestamp,
  };
}

describe("forecast severity band mappers", () => {
  it("maps heat thresholds to safe, caution, and unsafe", () => {
    expect(heatBand(84.9)).toBe(Band.safe);
    expect(heatBand(85)).toBe(Band.caution);
    expect(heatBand(95)).toBe(Band.unsafe);
  });

  it("maps cold thresholds using wind chill", () => {
    expect(coldBand(40, 5)).toBe(Band.safe);
    expect(coldBand(25, 2)).toBe(Band.caution);
    expect(coldBand(-5, 2)).toBe(Band.unsafe);
  });

  it("combines heat and cold into a single temperature band", () => {
    expect(temperatureBand(baseWeather())).toBe(Band.safe);
    expect(temperatureBand(baseWeather({ feels_like_f: 90 }))).toBe(Band.caution);
    expect(temperatureBand(baseWeather({ temperature_f: -5, feels_like_f: 20 }))).toBe(Band.unsafe);
  });

  it("returns unknown for missing AQI and bands known AQI values", () => {
    expect(airQualityBand(null)).toBe(Band.unknown);
    expect(airQualityBand(101)).toBe(Band.caution);
    expect(airQualityBand(201)).toBe(Band.unsafe);
  });

  it("maps precipitation thresholds from rain and hazardous precip logic", () => {
    expect(precipitationBand(50, "rain")).toBe(Band.safe);
    expect(precipitationBand(80, "rain")).toBe(Band.caution);
    expect(precipitationBand(70, "freezing_rain")).toBe(Band.unsafe);
    expect(precipitationBand(10, "ice_pellets")).toBe(Band.unsafe);
  });

  it("maps wind, UV, and humidity thresholds", () => {
    expect(windBand(19)).toBe(Band.safe);
    expect(windBand(20)).toBe(Band.caution);
    expect(windBand(31)).toBe(Band.unsafe);

    expect(uvBand(7)).toBe(Band.safe);
    expect(uvBand(8)).toBe(Band.caution);
    expect(uvBand(11)).toBe(Band.unsafe);

    expect(humidityBand(90, 74)).toBe(Band.safe);
    expect(humidityBand(70, 75)).toBe(Band.caution);
    expect(humidityBand(80, 75)).toBe(Band.unsafe);
  });

  it("maps storm and pavement thresholds", () => {
    expect(stormBand(1000, 10)).toBe(Band.safe);
    expect(stormBand(1087, 10)).toBe(Band.caution);
    expect(stormBand(1276, 35)).toBe(Band.unsafe);

    expect(pavementBand(100, 1000, "2026-07-15T22:00:00-07:00")).toBe(Band.safe);
    expect(pavementBand(100, 1000, "2026-07-15T13:00:00-07:00")).toBe(Band.caution);
    expect(pavementBand(115, 1000, "2026-07-15T13:00:00-07:00")).toBe(Band.unsafe);
  });

  it("returns all criterion bands from a single weather entry", () => {
    const bands = mapForecastSeverityBands(
      hourlyWeather("2026-07-15T13:00:00-07:00", {
        feels_like_f: 92,
        temperature_f: 100,
        humidity: 78,
        wind_speed_mph: 24,
        precip_probability: 82,
        precip_type: "rain",
        weather_code: 1087,
        uv_index: 9,
        aqi: null,
      })
    );

    expect(bands).toEqual({
      temperature: Band.caution,
      precipitation: Band.caution,
      wind: Band.caution,
      uv: Band.caution,
      humidity: Band.caution,
      airQuality: Band.unknown,
      storm: Band.caution,
      pavement: Band.safe,
    });
  });
});
