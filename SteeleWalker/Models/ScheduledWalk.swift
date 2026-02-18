import Foundation

/// Firestore collection: `scheduled_walks`
/// Document ID: auto-generated
/// FK: `user_id` → `users/{id}`
/// FK: `schedule_id` → `walking_schedules/{id}`
///
/// A concrete walk instance for a specific date, derived from a
/// `WalkingSchedule` template. Created by the recommendation engine
/// (or eagerly when the schedule is saved) for each future date.
///
/// Keeping instances as separate documents lets the recommendation engine
/// attach computed optimal times, and lets future features store per-walk
/// metadata (e.g. weather snapshot at walk time) without modifying the template.
struct ScheduledWalk: Codable, Identifiable {
    /// Firestore document ID.
    let id: String

    /// Owner's Firebase Auth UID.
    let userId: String

    /// The `WalkingSchedule` template this instance was generated from.
    let scheduleId: String

    /// Calendar date of the walk in `"YYYY-MM-DD"` format, stored as a string
    /// for simple range queries without timezone conversion issues.
    let date: String

    /// Preferred start time copied from the originating `WalkSlot` at creation
    /// time, in `"HH:mm"` format. The recommendation engine may override this
    /// with a computed optimal time in a future field.
    let preferredTime: String

    /// Walk duration in minutes, copied from the originating slot.
    let durationMinutes: Int

    /// Walk order within the day (1-based), copied from the originating slot.
    let walkOrder: Int

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId          = "user_id"
        case scheduleId      = "schedule_id"
        case date
        case preferredTime   = "preferred_time"
        case durationMinutes = "duration_minutes"
        case walkOrder       = "walk_order"
        case createdAt       = "created_at"
    }
}
