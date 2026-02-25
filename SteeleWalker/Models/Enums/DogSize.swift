import Foundation

/// Physical size category of a dog, used for walk recommendations and UI display.
enum DogSize: String, Codable, CaseIterable {
    case extraSmall  = "extra_small"
    case small       = "small"
    case medium      = "medium"
    case large       = "large"
    case extraLarge  = "extra_large"

    var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small:      return "Small"
        case .medium:     return "Medium"
        case .large:      return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var weightRange: String {
        switch self {
        case .extraSmall: return "under 10 lbs"
        case .small:      return "10–25 lbs"
        case .medium:     return "25–50 lbs"
        case .large:      return "50–90 lbs"
        case .extraLarge: return "90+ lbs"
        }
    }
}
