import Foundation
import SwiftUI

/// Walk safety recommendation level — higher raw value = more restrictive.
/// Matches the server-side `RecommendationLevel` enum exactly.
enum RecommendationLevel: Int, Codable, Comparable {
    case optimal = 0
    case normalWalk = 1
    case shortWalk = 2
    case veryShortWalk = 3
    case bathroomOnly = 4
    case doNotWalk = 5

    static func < (lhs: RecommendationLevel, rhs: RecommendationLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .optimal:       return "Optimal"
        case .normalWalk:    return "Normal Walk"
        case .shortWalk:     return "Short Walk"
        case .veryShortWalk: return "Very Short Walk"
        case .bathroomOnly:  return "Bathroom Only"
        case .doNotWalk:     return "Do Not Walk"
        }
    }

    var description: String {
        switch self {
        case .optimal:       return "Great conditions for a walk!"
        case .normalWalk:    return "Good conditions with minor considerations."
        case .shortWalk:     return "Keep walks under 20 minutes."
        case .veryShortWalk: return "Limit to 10 minutes or less."
        case .bathroomOnly:  return "Quick bathroom breaks only (5 min max)."
        case .doNotWalk:     return "Conditions are unsafe. Stay indoors."
        }
    }

    var color: Color {
        switch self {
        case .optimal:       return .green
        case .normalWalk:    return .blue
        case .shortWalk:     return .yellow
        case .veryShortWalk: return .orange
        case .bathroomOnly:  return .red
        case .doNotWalk:     return .purple
        }
    }

    var systemImage: String {
        switch self {
        case .optimal:       return "checkmark.circle.fill"
        case .normalWalk:    return "figure.walk"
        case .shortWalk:     return "clock"
        case .veryShortWalk: return "exclamationmark.triangle"
        case .bathroomOnly:  return "exclamationmark.triangle.fill"
        case .doNotWalk:     return "xmark.octagon.fill"
        }
    }

    /// Initialize from the server's string key (e.g. "bathroom_only").
    init?(key: String) {
        switch key {
        case "optimal":        self = .optimal
        case "normal_walk":    self = .normalWalk
        case "short_walk":     self = .shortWalk
        case "very_short_walk": self = .veryShortWalk
        case "bathroom_only":  self = .bathroomOnly
        case "do_not_walk":    self = .doNotWalk
        default: return nil
        }
    }
}

// MARK: - Response Models

/// Top-level response from POST /walkRecommendation.
struct WalkRecommendation: Codable {
    let dogs: [DogRecommendationEntry]
    let household: HouseholdRecommendation
    let scheduledWalks: [ScheduledWalkRecommendation]
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case dogs
        case household
        case scheduledWalks = "scheduled_walks"
        case generatedAt    = "generated_at"
    }
}

/// A scheduled walk recommendation tied to the user's walking schedule.
struct ScheduledWalkRecommendation: Codable, Identifiable {
    let preferredTime: String        // "HH:mm"
    let recommendedTime: String?     // Optimized "HH:mm" within the walk window.
    let localTimestamp: String       // ISO 8601 with offset
    let dayLabel: String             // "Today", "Tomorrow", etc.
    let scheduleType: String         // "weekday" or "weekend"
    let durationMinutes: Int
    let recommendation: RecommendationDetail

    var id: String { localTimestamp }

    enum CodingKeys: String, CodingKey {
        case preferredTime   = "preferred_time"
        case recommendedTime = "recommended_time"
        case localTimestamp  = "local_timestamp"
        case dayLabel        = "day_label"
        case scheduleType    = "schedule_type"
        case durationMinutes = "duration_minutes"
        case recommendation
    }
}

/// Per-dog entry with current + hourly recommendations.
struct DogRecommendationEntry: Codable, Identifiable {
    let dogId: String
    let dogName: String
    let current: RecommendationDetail
    let hourly: [HourlyRecommendationDetail]

    var id: String { dogId }

    enum CodingKeys: String, CodingKey {
        case dogId   = "dogId"
        case dogName = "dogName"
        case current
        case hourly
    }
}

/// Household-level recommendation (most restrictive across all dogs).
struct HouseholdRecommendation: Codable {
    let current: RecommendationDetail
    let hourly: [HourlyRecommendationDetail]
}

/// Detailed recommendation for a single point in time.
struct RecommendationDetail: Codable {
    let level: Int
    let levelKey: String
    let maxDurationMin: Int?
    let reasons: [String]
    let hardStopReasons: [String]
    let modifierReasons: [String]

    enum CodingKeys: String, CodingKey {
        case level
        case levelKey         = "levelKey"
        case maxDurationMin   = "maxDurationMin"
        case reasons
        case hardStopReasons  = "hardStopReasons"
        case modifierReasons  = "modifierReasons"
    }

    /// Typed recommendation level.
    var recommendationLevel: RecommendationLevel {
        RecommendationLevel(rawValue: level) ?? .doNotWalk
    }
}

/// Hourly recommendation entry (simplified).
struct HourlyRecommendationDetail: Codable, Identifiable {
    let localTimestamp: String
    let level: Int
    let levelKey: String
    let reasons: [String]

    var id: String { localTimestamp }

    enum CodingKeys: String, CodingKey {
        case localTimestamp = "local_timestamp"
        case level
        case levelKey      = "levelKey"
        case reasons
    }

    /// Typed recommendation level.
    var recommendationLevel: RecommendationLevel {
        RecommendationLevel(rawValue: level) ?? .doNotWalk
    }

    /// Parses the ISO 8601 offset timestamp into a `Date`.
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: localTimestamp)
    }
}
