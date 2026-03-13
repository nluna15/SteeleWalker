import type { Request, Response } from "express";
import { verifyToken } from "../auth";
import { fetchForecast } from "./weatherApiClient";

function errorResponse(
  res: Response,
  status: number,
  message: string,
  code: string,
  details?: Record<string, unknown>
): void {
  res.status(status).json({ error: message, code, ...(details ? { details } : {}) });
}

/**
 * GET /weather/forecast/hourly
 *
 * Query params:
 *   lat   - required, numeric latitude
 *   lon   - required, numeric longitude
 *   units - optional, "imperial" (default) | "metric"
 *
 * Returns ForecastResponse: { current, hourly[48], timezone }
 */
export async function forecastHandler(req: Request, res: Response): Promise<void> {
  if (req.method !== "GET") {
    errorResponse(res, 405, "Method not allowed", "METHOD_NOT_ALLOWED");
    return;
  }

  // 1. Authenticate
  let uid: string;
  try {
    uid = await verifyToken(req.headers.authorization);
  } catch (err: unknown) {
    const e = err as { status?: number; message?: string };
    errorResponse(res, e.status ?? 401, e.message ?? "Unauthorized", "UNAUTHORIZED");
    return;
  }

  // Suppress unused uid warning — uid is verified but not needed downstream for this endpoint
  void uid;

  // 2. Validate query params
  const latRaw = req.query["lat"] as string | undefined;
  const lonRaw = req.query["lon"] as string | undefined;
  const unitsRaw = (req.query["units"] as string | undefined) ?? "imperial";

  if (!latRaw || !lonRaw) {
    errorResponse(res, 400, "lat and lon query parameters are required", "INVALID_REQUEST");
    return;
  }

  const lat = parseFloat(latRaw);
  const lon = parseFloat(lonRaw);

  if (isNaN(lat) || isNaN(lon)) {
    errorResponse(res, 400, "lat and lon must be numeric", "INVALID_REQUEST");
    return;
  }

  if (lat < -90 || lat > 90) {
    errorResponse(res, 400, "lat must be between -90 and 90", "INVALID_REQUEST");
    return;
  }

  if (lon < -180 || lon > 180) {
    errorResponse(res, 400, "lon must be between -180 and 180", "INVALID_REQUEST");
    return;
  }

  const units = unitsRaw === "metric" ? "metric" : "imperial";

  // 3. Fetch forecast
  try {
    const forecast = await fetchForecast(lat, lon, units);
    res.status(200).json(forecast);
  } catch (err: unknown) {
    const e = err as { response?: { status?: number; data?: unknown }; message?: string };

    if (e.response) {
      const upstreamStatus = e.response.status ?? 500;
      if (upstreamStatus === 429) {
        errorResponse(res, 503, "Weather provider rate limit exceeded; please retry later", "UPSTREAM_RATE_LIMIT");
      } else {
        errorResponse(res, 502, "Weather provider returned an error", "UPSTREAM_ERROR", {
          upstreamStatus,
          upstreamBody: e.response.data,
        });
      }
    } else {
      console.error("[forecastHandler] Unexpected error:", e.message, err);
      errorResponse(res, 500, "Internal server error", "INTERNAL_ERROR");
    }
  }
}
