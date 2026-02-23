import FirebaseFirestore

struct WalkLogService {

    // MARK: - Create

    /// Creates a walk log.
    ///
    /// If `scheduledWalkId` is non-nil, uses a `WriteBatch` to atomically:
    /// 1. Add the new `walk_logs` document.
    /// 2. Set the linked `scheduled_walks` document's `status` to `"completed"`.
    ///
    /// Returns the generated walk log document ID.
    static func addWalkLog(
        userId: String,
        date: String,
        dogIds: [String],
        scheduledWalkId: String? = nil
    ) async throws -> String {
        let db = Firestore.firestore()
        let logRef = db.collection("walk_logs").document()

        var data: [String: Any] = [
            "id":         logRef.documentID,
            "user_id":    userId,
            "date":       date,
            "dog_ids":    dogIds,
            "started_at": FieldValue.serverTimestamp()
        ]
        if let scheduledWalkId {
            data["scheduled_walk_id"] = scheduledWalkId
        }

        if let scheduledWalkId {
            let batch = db.batch()
            batch.setData(data, forDocument: logRef)
            let scheduleRef = db.collection("scheduled_walks").document(scheduledWalkId)
            batch.updateData([
                "status":     ScheduledWalkStatus.completed.rawValue,
                "updated_at": FieldValue.serverTimestamp()
            ], forDocument: scheduleRef)
            try await batch.commit()
        } else {
            try await logRef.setData(data)
        }

        return logRef.documentID
    }

    // MARK: - Read

    /// Returns all walk logs for a user on a given date.
    static func fetchWalkLogs(userId: String, date: String) async throws -> [WalkLog] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("walk_logs")
            .whereField("user_id", isEqualTo: userId)
            .whereField("date",    isEqualTo: date)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: WalkLog.self) }
    }

    /// Returns walk log history for a user, newest first.
    static func fetchWalkLogHistory(userId: String) async throws -> [WalkLog] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("walk_logs")
            .whereField("user_id", isEqualTo: userId)
            .order(by: "started_at", descending: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: WalkLog.self) }
    }

    // MARK: - Delete

    /// Deletes a walk log.
    ///
    /// If `scheduledWalkId` is non-nil, uses a `WriteBatch` to atomically:
    /// 1. Delete the `walk_logs` document.
    /// 2. Revert the linked `scheduled_walks` document's `status` back to `"pending"`.
    static func deleteWalkLog(id: String, scheduledWalkId: String? = nil) async throws {
        let db = Firestore.firestore()
        let logRef = db.collection("walk_logs").document(id)

        if let scheduledWalkId {
            let batch = db.batch()
            batch.deleteDocument(logRef)
            let scheduleRef = db.collection("scheduled_walks").document(scheduledWalkId)
            batch.updateData([
                "status":     ScheduledWalkStatus.pending.rawValue,
                "updated_at": FieldValue.serverTimestamp()
            ], forDocument: scheduleRef)
            try await batch.commit()
        } else {
            try await logRef.delete()
        }
    }
}
