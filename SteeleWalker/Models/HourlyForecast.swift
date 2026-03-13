import Foundation

/// A single hourly forecast entry from the Cloud Function response.
/// Mirrors `WeatherSnapshot` fields plus a timezone-aware local timestamp.
struct HourlyForecast: Codable, Identifiable {
    let temperatureF: Double
    let feelsLikeF: Double
    let humidity: Int
    let windSpeedMph: Double
    let precipProbability: Int
    let precipType: String?
    let weatherCode: Int
    let conditionText: String
    let uvIndex: Int
    let aqi: Int?
    let windDirectionDeg: Int
    let capturedAt: Date
    let localTimestamp: String

    var id: String { localTimestamp }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        temperatureF      = try c.decode(Double.self, forKey: .temperatureF)
        feelsLikeF        = try c.decode(Double.self, forKey: .feelsLikeF)
        humidity          = try c.decode(Int.self, forKey: .humidity)
        windSpeedMph      = try c.decode(Double.self, forKey: .windSpeedMph)
        precipProbability = try c.decode(Int.self, forKey: .precipProbability)
        precipType        = try c.decodeIfPresent(String.self, forKey: .precipType)
        weatherCode       = try c.decode(Int.self, forKey: .weatherCode)
        conditionText     = try c.decode(String.self, forKey: .conditionText)
        uvIndex           = try c.decode(Int.self, forKey: .uvIndex)
        aqi               = try c.decodeIfPresent(Int.self, forKey: .aqi)
        windDirectionDeg  = try c.decodeIfPresent(Int.self, forKey: .windDirectionDeg) ?? 0
        capturedAt        = try c.decode(Date.self, forKey: .capturedAt)
        localTimestamp    = try c.decode(String.self, forKey: .localTimestamp)
    }

    enum CodingKeys: String, CodingKey {
        case temperatureF      = "temperature_f"
        case feelsLikeF        = "feels_like_f"
        case humidity
        case windSpeedMph      = "wind_speed_mph"
        case precipProbability = "precip_probability"
        case precipType        = "precip_type"
        case weatherCode       = "weather_code"
        case conditionText     = "condition_text"
        case uvIndex           = "uv_index"
        case aqi               = "aqi"
        case windDirectionDeg  = "wind_direction_deg"
        case capturedAt        = "captured_at"
        case localTimestamp    = "local_timestamp"
    }

    /// Parses the ISO 8601 offset timestamp into a `Date`.
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: localTimestamp)
    }

    /// 8-point cardinal direction derived from `windDirectionDeg`.
    var windCardinal: String {
        WeatherSnapshot.cardinal(from: windDirectionDeg)
    }
}
