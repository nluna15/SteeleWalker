import axios from "axios";

// Mock axios before importing the module under test
jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;

// Set the required env var before importing weatherApiClient
process.env.WEATHER_API_KEY = "test-api-key";

import { fetchForecast } from "../weatherApiClient";

/** Helper to build a WeatherAPI current object. */
function makeCurrent(
  overrides: Partial<{
    temp_f: number;
    feelslike_f: number;
    humidity: number;
    wind_mph: number;
    wind_degree: number;
    condition: { text: string; code: number };
    uv: number;
    air_quality: { "us-epa-index"?: number };
  }> = {}
) {
  return {
    temp_f: 72.0,
    feelslike_f: 70.0,
    humidity: 60,
    wind_mph: 8.0,
    wind_degree: 180,
    condition: { text: "Sunny", code: 1000 },
    uv: 5,
    air_quality: { "us-epa-index": 42 },
    ...overrides,
  };
}

/** Helper to build a WeatherAPI hour object. */
function makeHour(
  time: string,
  overrides: Partial<{
    temp_f: number;
    feelslike_f: number;
    humidity: number;
    wind_mph: number;
    wind_degree: number;
    chance_of_rain: number;
    chance_of_snow: number;
    condition: { text: string; code: number };
    uv: number;
  }> = {}
) {
  return {
    time,
    time_epoch: Math.floor(new Date(time.replace(" ", "T") + ":00Z").getTime() / 1000),
    temp_f: 72.0,
    feelslike_f: 70.0,
    humidity: 60,
    wind_mph: 8.0,
    wind_degree: 180,
    chance_of_rain: 10,
    chance_of_snow: 0,
    condition: { text: "Sunny", code: 1000 },
    uv: 5,
    ...overrides,
  };
}

/** Build 24 hourly entries for a single forecast day. */
function makeDay(dateStr: string, count = 24) {
  return Array.from({ length: count }, (_, i) => {
    const hour = String(i).padStart(2, "0");
    return makeHour(`${dateStr} ${hour}:00`);
  });
}

/** Build a full WeatherAPI mock response. */
function makeMockResponse(
  timezone = "America/Los_Angeles",
  currentOverrides: Parameters<typeof makeCurrent>[0] = {},
  forecastDays?: ReturnType<typeof makeHour>[][]
) {
  const days = forecastDays ?? [
    makeDay("2026-03-04"),
    makeDay("2026-03-05"),
  ];

  return {
    data: {
      location: { tz_id: timezone },
      current: makeCurrent(currentOverrides),
      forecast: {
        forecastday: days.map((hours) => ({ hour: hours })),
      },
    },
  };
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe("fetchForecast", () => {
  it("returns a ForecastResponse with current + 48 hourly entries", async () => {
    mockedAxios.get.mockResolvedValueOnce(makeMockResponse());

    const result = await fetchForecast(34.05, -118.24);

    expect(result.current).toBeDefined();
    expect(result.hourly).toHaveLength(48);
    expect(result.timezone).toBe("America/Los_Angeles");
  });

  it("maps temperature, humidity, wind, and uv correctly", async () => {
    mockedAxios.get.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", {
        temp_f: 75.5,
        feelslike_f: 73.0,
        humidity: 55,
        wind_mph: 12.3,
        uv: 7,
      })
    );

    const result = await fetchForecast(34.05, -118.24);

    expect(result.current.temperature_f).toBe(75.5);
    expect(result.current.feels_like_f).toBe(73.0);
    expect(result.current.humidity).toBe(55);
    expect(result.current.wind_speed_mph).toBe(12.3);
    expect(result.current.uv_index).toBe(7);
  });

  it("maps aqi from air_quality us-epa-index", async () => {
    mockedAxios.get.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", {
        air_quality: { "us-epa-index": 85 },
      })
    );

    const result = await fetchForecast(34.05, -118.24);
    expect(result.current.aqi).toBe(85);
  });

  it("returns aqi: null when air_quality is absent", async () => {
    const current = makeCurrent();
    delete (current as Record<string, unknown>).air_quality;
    mockedAxios.get.mockResolvedValueOnce({
      data: {
        location: { tz_id: "America/Los_Angeles" },
        current,
        forecast: {
          forecastday: [
            { hour: makeDay("2026-03-04") },
            { hour: makeDay("2026-03-05") },
          ],
        },
      },
    });

    const result = await fetchForecast(34.05, -118.24);
    expect(result.current.aqi).toBeNull();
  });

  it("returns aqi: null for hourly entries", async () => {
    mockedAxios.get.mockResolvedValueOnce(makeMockResponse());

    const result = await fetchForecast(34.05, -118.24);
    result.hourly.forEach((entry) => {
      expect(entry.aqi).toBeNull();
    });
  });

  describe("precipType from condition codes", () => {
    const cases: [number, string, string][] = [
      [1066, "Patchy snow possible", "snow"],
      [1114, "Blowing snow", "snow"],
      [1210, "Patchy light snow", "snow"],
      [1063, "Patchy rain possible", "rain"],
      [1153, "Light drizzle", "rain"],
      [1195, "Heavy rain", "rain"],
      [1069, "Patchy sleet possible", "freezing_rain"],
      [1204, "Light sleet", "freezing_rain"],
      [1237, "Ice pellets", "ice_pellets"],
      [1261, "Light showers of ice pellets", "ice_pellets"],
    ];

    test.each(cases)(
      "condition code %i (%s) → %s",
      async (code, conditionText, expected) => {
        mockedAxios.get.mockResolvedValueOnce(
          makeMockResponse("America/Los_Angeles", {
            condition: { text: conditionText, code },
          })
        );

        const result = await fetchForecast(34.05, -118.24);
        expect(result.current.precip_type).toBe(expected);
      }
    );
  });

  describe("precipType from chance_of_rain / chance_of_snow", () => {
    it("returns snow when chance_of_snow > chance_of_rain", async () => {
      const hours = makeDay("2026-03-04").map((h) => ({
        ...h,
        chance_of_rain: 10,
        chance_of_snow: 60,
        condition: { text: "Overcast", code: 1009 },
      }));
      const hours2 = makeDay("2026-03-05").map((h) => ({
        ...h,
        chance_of_rain: 10,
        chance_of_snow: 60,
        condition: { text: "Overcast", code: 1009 },
      }));

      mockedAxios.get.mockResolvedValueOnce(
        makeMockResponse("America/Los_Angeles", {
          condition: { text: "Overcast", code: 1009 },
        }, [hours, hours2])
      );

      const result = await fetchForecast(34.05, -118.24);
      // Current should derive from first hour's chances since code 1009 has no precip mapping
      expect(result.current.precip_type).toBe("snow");
    });

    it("returns rain when chance_of_rain > 0 and no snow", async () => {
      const hours = makeDay("2026-03-04").map((h) => ({
        ...h,
        chance_of_rain: 40,
        chance_of_snow: 0,
        condition: { text: "Overcast", code: 1009 },
      }));
      const hours2 = makeDay("2026-03-05").map((h) => ({
        ...h,
        chance_of_rain: 40,
        chance_of_snow: 0,
        condition: { text: "Overcast", code: 1009 },
      }));

      mockedAxios.get.mockResolvedValueOnce(
        makeMockResponse("America/Los_Angeles", {
          condition: { text: "Overcast", code: 1009 },
        }, [hours, hours2])
      );

      const result = await fetchForecast(34.05, -118.24);
      expect(result.current.precip_type).toBe("rain");
    });

    it("returns null when no precipitation", async () => {
      const hours = makeDay("2026-03-04").map((h) => ({
        ...h,
        chance_of_rain: 0,
        chance_of_snow: 0,
        condition: { text: "Sunny", code: 1000 },
      }));
      const hours2 = makeDay("2026-03-05").map((h) => ({
        ...h,
        chance_of_rain: 0,
        chance_of_snow: 0,
        condition: { text: "Sunny", code: 1000 },
      }));

      mockedAxios.get.mockResolvedValueOnce(
        makeMockResponse("America/Los_Angeles", {
          condition: { text: "Sunny", code: 1000 },
        }, [hours, hours2])
      );

      const result = await fetchForecast(34.05, -118.24);
      expect(result.current.precip_type).toBeNull();
    });
  });

  describe("conditionText from WeatherAPI", () => {
    const cases: [number, string][] = [
      [1000, "Sunny"],
      [1003, "Partly cloudy"],
      [1006, "Cloudy"],
      [1009, "Overcast"],
      [1030, "Mist"],
      [1195, "Heavy rain"],
      [1225, "Heavy snow"],
      [8000, "Unknown code"],
    ];

    test.each(cases)(
      "condition code %i → '%s'",
      async (code, expectedText) => {
        mockedAxios.get.mockResolvedValueOnce(
          makeMockResponse("America/Los_Angeles", {
            condition: { text: expectedText, code },
          })
        );

        const result = await fetchForecast(34.05, -118.24);
        expect(result.current.condition_text).toBe(expectedText);
      }
    );
  });

  it("applies timezone offset to local_timestamp of first hourly entry", async () => {
    mockedAxios.get.mockResolvedValueOnce(makeMockResponse("America/Los_Angeles"));

    const result = await fetchForecast(34.05, -118.24);
    const first = result.hourly[0];

    // Should contain a timezone offset (not Z)
    expect(first.local_timestamp).toMatch(/[+-]\d{2}:\d{2}$/);
    // Should contain date and time
    expect(first.local_timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  });

  it("limits hourly to 48 entries even if WeatherAPI returns more", async () => {
    // 3 days = 72 hours
    const days = [
      makeDay("2026-03-04"),
      makeDay("2026-03-05"),
      makeDay("2026-03-06"),
    ];
    mockedAxios.get.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", {}, days)
    );

    const result = await fetchForecast(34.05, -118.24);
    expect(result.hourly).toHaveLength(48);
  });

  it("throws when WEATHER_API_KEY is not set", async () => {
    const saved = process.env.WEATHER_API_KEY;
    delete process.env.WEATHER_API_KEY;

    await expect(fetchForecast(34.05, -118.24)).rejects.toThrow(
      "WEATHER_API_KEY environment variable is not set"
    );

    process.env.WEATHER_API_KEY = saved;
  });

  it("throws when WeatherAPI returns no hourly data", async () => {
    mockedAxios.get.mockResolvedValueOnce({
      data: {
        location: { tz_id: "UTC" },
        current: makeCurrent(),
        forecast: { forecastday: [] },
      },
    });

    await expect(fetchForecast(34.05, -118.24)).rejects.toThrow(
      "Weather provider returned no hourly forecast data"
    );
  });

  it("calls axios.get with correct params", async () => {
    mockedAxios.get.mockResolvedValueOnce(makeMockResponse());

    await fetchForecast(34.05, -118.24);

    expect(mockedAxios.get).toHaveBeenCalledWith(
      "https://api.weatherapi.com/v1/forecast.json",
      {
        params: {
          key: "test-api-key",
          q: "34.05,-118.24",
          days: 2,
          aqi: "yes",
        },
      }
    );
  });
});
