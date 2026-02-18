import Foundation

/// Differentiates a recurring walking schedule between weekday and weekend patterns.
/// An owner may have one WalkingSchedule per type.
enum ScheduleType: String, Codable, CaseIterable {
    case weekday = "weekday"
    case weekend = "weekend"

    var displayName: String {
        switch self {
        case .weekday: return "Weekday"
        case .weekend: return "Weekend"
        }
    }
}
