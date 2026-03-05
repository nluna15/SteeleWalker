import axios from "axios";

// Mock axios before importing the module under test
jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;

// Set the required env var before importing tomorrowClient
process.env.TOMORROW_IO_API_KEY = "test-api-key";

import { fetchForecast } from "../tomorrowClient";

/** Helper to build a minimal Tomorrow.io interval. */
function makeInterval(
  startTime: string,
  overrides: Partial<{
    temperature: number;
    temperatureApparent: number;
    humidity: number;
    windSpeed: number;
    precipitationProbability: number;
    precipitationType: number;
    weatherCode: number;
    uvIndex: number;
    epaIndex: number;
  }> = {}
) {
  return {
    startTime,
    values: {
      temperature: 72.0,
      temperatureApparent: 70.0,
      humidity: 60,
      windSpeed: 8.0,
      precipitationProbability: 10,
      precipitationType: 0,
      weatherCode: 1000,
      uvIndex: 5,
      epaIndex: 42,
      ...overrides,
    },
  };
}

/** Build 48 hourly intervals starting from a base ISO string. */
function makeHourlyIntervals(baseIso: string, count = 48) {
  const base = new Date(baseIso).getTime();
  return Array.from({ length: count }, (_, i) => {
    const t = new Date(base + i * 60 * 60 * 1000).toISOString();
    return makeInterval(t);
  });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function makeMockResponse(
  timezone = "America/Los_Angeles",
  currentInterval: Record<string, unknown> = makeInterval("2026-03-04T16:00:00Z"),
  hourlyIntervals: Record<string, unknown>[] = makeHourlyIntervals("2026-03-04T16:00:00Z")
) {
  return {
    data: {
      data: {
        timelines: [
          {
            timestep: "current",
            timezone,
            intervals: [currentInterval],
          },
          {
            timestep: "1h",
            timezone,
            intervals: hourlyIntervals,
          },
        ],
      },
    },
  };
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe("fetchForecast", () => {
  it("returns a ForecastResponse with current + 48 hourly entries", async () => {
    mockedAxios.post.mockResolvedValueOnce(makeMockResponse());

    const result = await fetchForecast(34.05, -118.24);

    expect(result.current).toBeDefined();
    expect(result.hourly).toHaveLength(48);
    expect(result.timezone).toBe("America/Los_Angeles");
  });

  it("maps temperature, humidity, wind, and uv correctly", async () => {
    const interval = makeInterval("2026-03-04T16:00:00Z", {
      temperature: 75.5,
      temperatureApparent: 73.0,
      humidity: 55,
      windSpeed: 12.3,
      uvIndex: 7,
    });
    mockedAxios.post.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", interval, makeHourlyIntervals("2026-03-04T16:00:00Z"))
    );

    const result = await fetchForecast(34.05, -118.24);

    expect(result.current.temperature_f).toBe(75.5);
    expect(result.current.feels_like_f).toBe(73.0);
    expect(result.current.humidity).toBe(55);
    expect(result.current.wind_speed_mph).toBe(12.3);
    expect(result.current.uv_index).toBe(7);
  });

  it("maps aqi from epaIndex", async () => {
    const interval = makeInterval("2026-03-04T16:00:00Z", { epaIndex: 85 });
    mockedAxios.post.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", interval, makeHourlyIntervals("2026-03-04T16:00:00Z"))
    );

    const result = await fetchForecast(34.05, -118.24);
    expect(result.current.aqi).toBe(85);
  });

  it("returns aqi: null when epaIndex is absent", async () => {
    const interval = {
      startTime: "2026-03-04T16:00:00Z",
      values: {
        temperature: 72.0,
        temperatureApparent: 70.0,
        humidity: 60,
        windSpeed: 8.0,
        precipitationProbability: 10,
        precipitationType: 0,
        weatherCode: 1000,
        uvIndex: 5,
        // epaIndex intentionally omitted
      },
    };
    mockedAxios.post.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", interval, makeHourlyIntervals("2026-03-04T16:00:00Z"))
    );

    const result = await fetchForecast(34.05, -118.24);
    expect(result.current.aqi).toBeNull();
  });

  describe("precipitationType mapping", () => {
    const cases: [number, string | null][] = [
      [0, null],
      [1, "rain"],
      [2, "snow"],
      [3, "freezing_rain"],
      [4, "ice_pellets"],
    ];

    test.each(cases)(
      "precipitationType %i → %s",
      async (typeCode, expected) => {
        const interval = makeInterval("2026-03-04T16:00:00Z", { precipitationType: typeCode });
        mockedAxios.post.mockResolvedValueOnce(
          makeMockResponse("America/Los_Angeles", interval, makeHourlyIntervals("2026-03-04T16:00:00Z"))
        );

        const result = await fetchForecast(34.05, -118.24);
        expect(result.current.precip_type).toBe(expected);
      }
    );
  });

  describe("conditionText mapping", () => {
    const cases: [number, string][] = [
      [1000, "Clear"],
      [1001, "Cloudy"],
      [1100, "Mostly Clear"],
      [2000, "Fog"],
      [4001, "Rain"],
      [5001, "Flurries"],
      [5100, "Light Snow"],
      [5000, "Snow"],
      [6000, "Freezing Drizzle"],
      [8000, "Thunderstorm"],
    ];

    test.each(cases)(
      "weatherCode %i → %s",
      async (code, expectedText) => {
        const interval = makeInterval("2026-03-04T16:00:00Z", { weatherCode: code });
        mockedAxios.post.mockResolvedValueOnce(
          makeMockResponse("America/Los_Angeles", interval, makeHourlyIntervals("2026-03-04T16:00:00Z"))
        );

        const result = await fetchForecast(34.05, -118.24);
        expect(result.current.condition_text).toBe(expectedText);
      }
    );
  });

  it("applies timezone offset to local_timestamp of first hourly entry", async () => {
    // UTC 2026-03-04T16:00:00Z → America/Los_Angeles (UTC-8 in March = PST) → 08:00-08:00
    const hourlyIntervals = makeHourlyIntervals("2026-03-04T16:00:00Z");
    mockedAxios.post.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", makeInterval("2026-03-04T16:00:00Z"), hourlyIntervals)
    );

    const result = await fetchForecast(34.05, -118.24);
    const first = result.hourly[0];

    // Should contain a timezone offset (not Z)
    expect(first.local_timestamp).toMatch(/[+-]\d{2}:\d{2}$/);
    // Should contain date and time
    expect(first.local_timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  });

  it("limits hourly to 48 entries even if Tomorrow.io returns more", async () => {
    const hourlyIntervals = makeHourlyIntervals("2026-03-04T16:00:00Z", 60);
    mockedAxios.post.mockResolvedValueOnce(
      makeMockResponse("America/Los_Angeles", makeInterval("2026-03-04T16:00:00Z"), hourlyIntervals)
    );

    const result = await fetchForecast(34.05, -118.24);
    expect(result.hourly).toHaveLength(48);
  });

  it("throws when TOMORROW_IO_API_KEY is not set", async () => {
    const saved = process.env.TOMORROW_IO_API_KEY;
    delete process.env.TOMORROW_IO_API_KEY;

    await expect(fetchForecast(34.05, -118.24)).rejects.toThrow(
      "TOMORROW_IO_API_KEY environment variable is not set"
    );

    process.env.TOMORROW_IO_API_KEY = saved;
  });

  it("throws when Tomorrow.io returns no current data", async () => {
    const response = {
      data: {
        data: {
          timelines: [
            { timestep: "current", timezone: "UTC", intervals: [] },
            { timestep: "1h", timezone: "UTC", intervals: makeHourlyIntervals("2026-03-04T16:00:00Z") },
          ],
        },
      },
    };
    mockedAxios.post.mockResolvedValueOnce(response);

    await expect(fetchForecast(34.05, -118.24)).rejects.toThrow(
      "Tomorrow.io returned no current conditions data"
    );
  });
});
