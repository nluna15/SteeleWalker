import { initializeApp } from "firebase-admin/app";
import { onRequest } from "firebase-functions/v2/https";
import { forecastHandler } from "./weather/forecast";
import { recommendationHandler } from "./recommendation/handler";

// Initialize Firebase Admin SDK once at module load.
initializeApp();

/**
 * GET /weatherForecastHourly
 *
 * Proxies current conditions + 48-hour hourly forecast from WeatherAPI.
 * Requires Firebase ID token in Authorization: Bearer header.
 *
 * Query params: lat, lon, units (optional, default "imperial")
 *
 * Emulator URL: http://localhost:5001/<project>/us-central1/weatherForecastHourly
 */
export const weatherForecastHourly = onRequest(
  { cors: false, secrets: ["WEATHER_API_KEY"] },
  forecastHandler
);

/**
 * POST /walkRecommendation
 *
 * Evaluates walk safety for each dog based on weather conditions and health profile.
 * Requires Firebase ID token in Authorization: Bearer header.
 *
 * Body: { dogIds: string[], weather: ForecastResponse }
 *
 * Emulator URL: http://localhost:5001/<project>/us-central1/walkRecommendation
 */
export const walkRecommendation = onRequest(
  { cors: false },
  recommendationHandler
);
