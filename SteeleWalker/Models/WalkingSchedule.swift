import Foundation

// MARK: - WalkSlot

/// A single time slot within a WalkingSchedule template.
///
/// Firestore sub-structure (embedded array inside a `walking_schedules` document).
struct WalkSlot: Codable {
    /// Preferred start time in `"HH:mm"` format (24-hour), e.g. `"07:00"`.
    /// The recommendation engine uses this as the centre of a 60–90 min window
    /// and picks the optimal minute within that range.
    let preferredTime: String

    /// Target walk duration in minutes (e.g. 30, 45, 60).
    let durationMinutes: Int

    /// 1-based ordering of this slot within the schedule (first walk = 1).
    let walkOrder: Int

    enum CodingKeys: String, CodingKey {
        case preferredTime   = "preferred_time"
        case durationMinutes = "duration_minutes"
        case walkOrder       = "walk_order"
    }
}

// MARK: - WalkingSchedule

/// Firestore collection: `walking_schedules`
/// Document ID: auto-generated
/// FK: `user_id` → `users/{id}`
///
/// Recurring template that defines *when* an owner typically walks their dogs.
/// Separate from `ScheduledWalk` (instances) — this is the source-of-truth
/// template the recommendation engine reads to generate daily walk instances.
///
/// One schedule per `ScheduleType` per user (at most two documents per user:
/// one weekday, one weekend).
struct WalkingSchedule: Codable, Identifiable {
    /// Firestore document ID.
    let id: String

    /// Owner's Firebase Auth UID — matches `users/{user_id}`.
    let userId: String

    /// Whether this schedule applies on weekdays or weekends.
    let scheduleType: ScheduleType

    /// Ordered walk slots for this schedule. Ordered by `walkOrder` ascending.
    let slots: [WalkSlot]

    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId       = "user_id"
        case scheduleType = "schedule_type"
        case slots
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }
}
