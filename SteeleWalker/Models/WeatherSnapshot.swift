import Foundation

/// A point-in-time weather reading from Tomorrow.io, embedded in both
/// `ScheduledWalk` and `WalkLog` documents.
///
/// Denormalized on each document so that `walk_logs` trend queries
/// (e.g. last 14 days) require a single collection scan with no joins.
///
/// Fields were chosen to map directly to `DogSensitivity` cases:
/// - `precipType` / `precipProbability` → `.rain`
/// - `weatherCode` (8000 range)         → `.thunder_lightning`
/// - `temperatureF` / `feelsLikeF` high → `.extreme_heat`
/// - `temperatureF` / `feelsLikeF` low  → `.extreme_cold`
/// - `windSpeedMph`                     → `.wind`
struct WeatherSnapshot: Codable {
    /// Actual temperature in °F.
    let temperatureF: Double

    /// Apparent ("feels like") temperature in °F.
    let feelsLikeF: Double

    /// Relative humidity, 0–100.
    let humidity: Int

    /// Wind speed in mph.
    let windSpeedMph: Double

    /// Precipitation probability, 0–100.
    let precipProbability: Int

    /// Precipitation type: `"rain"`, `"snow"`, `"freezing_rain"`,
    /// `"ice_pellets"`, or `nil` when no precipitation is expected.
    let precipType: String?

    /// Tomorrow.io weather code (e.g. 1000 = Clear, 4001 = Rain, 8000 = Thunderstorm).
    let weatherCode: Int

    /// Human-readable condition label derived from `weatherCode`
    /// (e.g. `"Clear"`, `"Rain"`, `"Thunderstorm"`).
    let conditionText: String

    /// UV index (0–11+).
    let uvIndex: Int

    /// Air Quality Index (EPA scale, 0–500+), or nil if unavailable.
    let aqi: Int?

    /// Wind direction in degrees (0–360). Defaults to 0 when the backend
    /// hasn't been redeployed with this field yet.
    let windDirectionDeg: Int

    /// Timestamp when Tomorrow.io was queried.
    let capturedAt: Date

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
    }

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
    }

    /// 8-point cardinal direction derived from `windDirectionDeg`.
    var windCardinal: String {
        Self.cardinal(from: windDirectionDeg)
    }

    static func cardinal(from degrees: Int) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((Double(degrees) + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return directions[index]
    }
}
