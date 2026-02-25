import FirebaseFirestore

struct WalkSlotInput: Sendable {
    let preferredTime: String
    let durationMinutes: Int
    let walkOrder: Int

    var asDictionary: [String: Any] {
        [
            "preferred_time":   preferredTime,
            "duration_minutes": durationMinutes,
            "walk_order":       walkOrder
        ]
    }
}

struct WalkingScheduleService {

    // MARK: - Document ID

    /// Deterministic document ID: `"\(userId)_\(scheduleType)"`.
    /// Enforces one-per-type-per-user at the Firestore level.
    private static func documentId(userId: String, scheduleType: String) -> String {
        "\(userId)_\(scheduleType)"
    }

    // MARK: - Create / Update (idempotent)

    /// Creates or updates a walking schedule using merge semantics.
    /// Calling this twice with the same `userId` and `scheduleType` is safe.
    static func setSchedule(
        userId: String,
        scheduleType: String,
        walksPerDay: Int,
        slots: [WalkSlotInput]
    ) async throws {
        let db = Firestore.firestore()
        let docId = documentId(userId: userId, scheduleType: scheduleType)
        let data: [String: Any] = [
            "id":             docId,
            "user_id":        userId,
            "schedule_type":  scheduleType,
            "walks_per_day":  walksPerDay,
            "slots":          slots.map(\.asDictionary),
            "updated_at":     FieldValue.serverTimestamp()
        ]
        try await db.collection("walking_schedules").document(docId).setData(data, merge: true)
    }

    // MARK: - Read

    /// Fetches a single schedule by user + type.
    static func fetchSchedule(userId: String, scheduleType: String) async throws -> WalkingSchedule {
        let db = Firestore.firestore()
        let docId = documentId(userId: userId, scheduleType: scheduleType)
        return try await db.collection("walking_schedules").document(docId).getDocument(as: WalkingSchedule.self)
    }

    /// Returns all schedules for a user (at most 2: weekday + weekend).
    static func fetchSchedules(userId: String) async throws -> [WalkingSchedule] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("walking_schedules")
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: WalkingSchedule.self) }
    }

    // MARK: - Delete

    /// Permanently deletes a schedule document.
    static func deleteSchedule(userId: String, scheduleType: String) async throws {
        let db = Firestore.firestore()
        let docId = documentId(userId: userId, scheduleType: scheduleType)
        try await db.collection("walking_schedules").document(docId).delete()
    }
}
