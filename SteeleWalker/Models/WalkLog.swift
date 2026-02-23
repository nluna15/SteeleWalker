import Foundation

/// Firestore collection: `walk_logs`
/// Document ID: auto-generated
/// FK: `user_id` → `users/{id}`
/// FK (optional): `scheduled_walk_id` → `scheduled_walks/{id}`
///
/// Records the moment a user tapped "I started this walk."
/// One log entry covers all dogs in the household (no per-dog split).
///
/// A `nil` `scheduledWalkId` means the walk was ad-hoc (not scheduled).
/// No completion timestamp, GPS route, or duration is stored — single-tap UX.
struct WalkLog: Codable, Identifiable {
    /// Firestore document ID.
    let id: String

    /// Owner's Firebase Auth UID.
    let userId: String

    /// Reference to the scheduled walk this log fulfils.
    /// `nil` for ad-hoc walks started outside the schedule.
    let scheduledWalkId: String?

    /// Calendar date of the walk in `"YYYY-MM-DD"` format. Stored separately
    /// from `startedAt` to allow efficient date-range queries without
    /// server-side date arithmetic.
    let date: String

    /// Exact timestamp when the user tapped "Start walk."
    let startedAt: Date

    /// IDs of the dogs that participated in this walk.
    let dogIds: [String]

    /// Weather conditions at walk-start time.
    ///
    /// For scheduled walks: copied from `ScheduledWalk.weatherSnapshot`
    /// (no additional API call). For ad-hoc walks: sourced from the
    /// in-memory snapshot cached at app launch. `nil` when no snapshot
    /// was available at walk-start time.
    let weatherSnapshot: WeatherSnapshot?

    enum CodingKeys: String, CodingKey {
        case id
        case userId           = "user_id"
        case scheduledWalkId  = "scheduled_walk_id"
        case date
        case startedAt        = "started_at"
        case dogIds           = "dog_ids"
        case weatherSnapshot  = "weather_snapshot"
    }
}
