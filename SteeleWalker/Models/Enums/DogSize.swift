import Foundation

/// Physical size category of a dog, used for walk recommendations and UI display.
enum DogSize: String, Codable, CaseIterable {
    case small       = "small"
    case medium      = "medium"
    case large       = "large"
    case extraLarge  = "extra_large"

    var displayName: String {
        switch self {
        case .small:      return "Small"
        case .medium:     return "Medium"
        case .large:      return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}
