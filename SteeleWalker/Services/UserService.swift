import FirebaseFirestore

struct UserService {

    static func fetchUser(uid: String) async throws -> User {
        let db = Firestore.firestore()
        return try await db.collection("users").document(uid).getDocument(as: User.self)
    }

    /// Updates user fields using merge semantics.
    /// Caller supplies a valid `[String: Any]` dict, e.g.:
    /// `["name": "New Name", "updated_at": FieldValue.serverTimestamp()]`
    static func updateUser(uid: String, fields: [String: Any]) async throws {
        let db = Firestore.firestore()
        try await db.collection("users").document(uid).updateData(fields)
    }
}
