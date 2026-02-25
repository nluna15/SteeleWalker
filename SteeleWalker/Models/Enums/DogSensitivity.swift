import Foundation

/// Weather and environmental sensitivities for a dog, stored as an array of
/// raw string keys in Firestore (e.g. `["rain", "extreme_heat"]`).
///
/// Sensitivity logic (how each condition impacts the walk recommendation) is
/// deferred to a future issue; this enum captures the data contract now.
enum DogSensitivity: String, Codable, CaseIterable {
    case rain             = "rain"
    case thunderLightning = "thunder_lightning"
    case extremeHeat      = "extreme_heat"
    case extremeCold      = "extreme_cold"
    case wind             = "wind"
    case allergens        = "allergens"

    var displayName: String {
        switch self {
        case .rain:             return "Rain"
        case .thunderLightning: return "Thunder & Lightning"
        case .extremeHeat:      return "Extreme Heat"
        case .extremeCold:      return "Extreme Cold"
        case .wind:             return "Wind"
        case .allergens:        return "Allergens"
        }
    }

    var systemImage: String {
        switch self {
        case .rain:             return "cloud.rain"
        case .thunderLightning: return "cloud.bolt.rain"
        case .extremeHeat:      return "thermometer.sun.fill"
        case .extremeCold:      return "thermometer.snowflake"
        case .wind:             return "wind"
        case .allergens:        return "leaf.circle"
        }
    }
}
