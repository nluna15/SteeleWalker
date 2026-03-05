import Foundation

/// Mobility level of a dog, collected during onboarding to pre-populate
/// `health_conditions` in Firestore without asking about individual conditions.
enum DogMobility: String, CaseIterable {
    case noRestrictions  = "no_restrictions"
    case seniorSlowerPace = "senior_slower_pace"
    case jointMobility   = "joint_mobility"
    case recovering      = "recovering"
    case other           = "other"

    var displayName: String {
        switch self {
        case .noRestrictions:   return "No restrictions"
        case .seniorSlowerPace: return "Senior — slower pace"
        case .jointMobility:    return "Joint / mobility issues"
        case .recovering:       return "Recovering from surgery"
        case .other:            return "Other"
        }
    }

    /// `DogHealthCondition` raw values that map to this mobility level.
    /// Used to populate `health_conditions` in Firestore during onboarding.
    var healthConditionKeys: [String] {
        switch self {
        case .noRestrictions:   return []
        case .seniorSlowerPace: return ["senior_mobility", "low_energy"]
        case .jointMobility:    return ["arthritis", "hip_issues"]
        case .recovering:       return ["recent_surgery"]
        case .other:            return []
        }
    }
}
