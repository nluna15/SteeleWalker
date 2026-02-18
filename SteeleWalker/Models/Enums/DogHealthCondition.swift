import Foundation

/// Structured health conditions for a dog, stored as an array of raw string keys
/// in Firestore (e.g. `["heart_condition", "arthritis"]`).
///
/// Using an array of enabled keys rather than a boolean map keeps the document
/// compact and makes it easy to add new conditions without a schema migration.
enum DogHealthCondition: String, Codable, CaseIterable {
    case heartCondition      = "heart_condition"
    case breathingDifficulty = "breathing_difficulty"
    case lowEnergy           = "low_energy"
    case arthritis           = "arthritis"
    case recentSurgery       = "recent_surgery"
    case hipIssues           = "hip_issues"
    case seniorMobility      = "senior_mobility"

    var displayName: String {
        switch self {
        case .heartCondition:      return "Heart Condition"
        case .breathingDifficulty: return "Breathing Difficulty"
        case .lowEnergy:           return "Low Energy"
        case .arthritis:           return "Arthritis"
        case .recentSurgery:       return "Recent Surgery"
        case .hipIssues:           return "Hip Issues"
        case .seniorMobility:      return "Senior Mobility Issues"
        }
    }
}
