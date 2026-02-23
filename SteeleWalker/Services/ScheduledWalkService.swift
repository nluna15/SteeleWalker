import FirebaseFirestore

struct ScheduledWalkService {

    // MARK: - Create

    /// Creates a new scheduled walk with `status: pending`.
    /// Returns the generated document ID.
    static func addScheduledWalk(
        userId: String,
        scheduleId: String,
        date: String,
        preferredTime: String,
        durationMinutes: Int,
        walkOrder: Int
    ) async throws -> String {
        let db = Firestore.firestore()
        let ref = db.collection("scheduled_walks").document()
        let data: [String: Any] = [
            "id":               ref.documentID,
            "user_id":          userId,
            "schedule_id":      scheduleId,
            "date":             date,
            "preferred_time":   preferredTime,
            "duration_minutes": durationMinutes,
            "walk_order":       walkOrder,
            "status":           ScheduledWalkStatus.pending.rawValue,
            "created_at":       FieldValue.serverTimestamp(),
            "updated_at":       FieldValue.serverTimestamp()
        ]
        try await ref.setData(data)
        return ref.documentID
    }

    // MARK: - Read

    /// Fetches a single scheduled walk by document ID.
    static func fetchScheduledWalk(id: String) async throws -> ScheduledWalk {
        let db = Firestore.firestore()
        return try await db.collection("scheduled_walks").document(id).getDocument(as: ScheduledWalk.self)
    }

    /// Returns all scheduled walks for a user on a given date, ordered by `walk_order`.
    static func fetchScheduledWalks(userId: String, date: String) async throws -> [ScheduledWalk] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("scheduled_walks")
            .whereField("user_id", isEqualTo: userId)
            .whereField("date",    isEqualTo: date)
            .order(by: "walk_order")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: ScheduledWalk.self) }
    }

    /// Returns all scheduled walks for a user within a date range (inclusive).
    static func fetchScheduledWalks(
        userId: String,
        startDate: String,
        endDate: String
    ) async throws -> [ScheduledWalk] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("scheduled_walks")
            .whereField("user_id", isEqualTo: userId)
            .whereField("date",    isGreaterThanOrEqualTo: startDate)
            .whereField("date",    isLessThanOrEqualTo: endDate)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: ScheduledWalk.self) }
    }

    // MARK: - Update

    /// Updates a scheduled walk with caller-supplied fields.
    /// `updated_at` is always appended automatically.
    static func updateScheduledWalk(id: String, fields: [String: Any]) async throws {
        let db = Firestore.firestore()
        var mutableFields = fields
        mutableFields["updated_at"] = FieldValue.serverTimestamp()
        try await db.collection("scheduled_walks").document(id).updateData(mutableFields)
    }

    // MARK: - Delete

    /// Permanently deletes a scheduled walk document.
    static func deleteScheduledWalk(id: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("scheduled_walks").document(id).delete()
    }

    /// Marks the scheduled walk as skipped without deleting the document.
    static func skipScheduledWalk(id: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("scheduled_walks").document(id).updateData([
            "status":     ScheduledWalkStatus.skipped.rawValue,
            "updated_at": FieldValue.serverTimestamp()
        ])
    }
}
