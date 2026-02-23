import FirebaseFirestore

struct DogService {

    // MARK: - Create

    /// Creates a new dog document and returns the generated document ID.
    static func addDog(
        userId: String,
        name: String,
        breedId: String,
        size: String,
        healthConditions: [String] = [],
        sensitivities: [String] = [],
        birthMonth: Int? = nil,
        birthYear: Int? = nil,
        weightLbs: Double? = nil,
        photoUrl: String? = nil,
        allergyNotes: String? = nil,
        healthNotes: String? = nil
    ) async throws -> String {
        let db = Firestore.firestore()
        let ref = db.collection("dogs").document()
        var data: [String: Any] = [
            "id":                ref.documentID,
            "user_id":           userId,
            "name":              name,
            "breed_id":          breedId,
            "size":              size,
            "health_conditions": healthConditions,
            "sensitivities":     sensitivities,
            "is_active":         true,
            "created_at":        FieldValue.serverTimestamp(),
            "updated_at":        FieldValue.serverTimestamp()
        ]
        if let birthMonth  { data["birth_month"]   = birthMonth }
        if let birthYear   { data["birth_year"]    = birthYear }
        if let weightLbs   { data["weight_lbs"]    = weightLbs }
        if let photoUrl    { data["photo_url"]      = photoUrl }
        if let allergyNotes { data["allergy_notes"] = allergyNotes }
        if let healthNotes  { data["health_notes"]  = healthNotes }

        try await ref.setData(data)
        return ref.documentID
    }

    // MARK: - Read

    /// Fetches a single dog by document ID.
    static func fetchDog(id: String) async throws -> Dog {
        let db = Firestore.firestore()
        return try await db.collection("dogs").document(id).getDocument(as: Dog.self)
    }

    /// Returns all active dogs for a user, ordered by creation time.
    static func fetchDogs(userId: String) async throws -> [Dog] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("dogs")
            .whereField("user_id",   isEqualTo: userId)
            .whereField("is_active", isEqualTo: true)
            .order(by: "created_at")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Dog.self) }
    }

    // MARK: - Update

    /// Updates a dog document with caller-supplied fields.
    /// `updated_at` is always appended automatically.
    static func updateDog(id: String, fields: [String: Any]) async throws {
        let db = Firestore.firestore()
        var mutableFields = fields
        mutableFields["updated_at"] = FieldValue.serverTimestamp()
        try await db.collection("dogs").document(id).updateData(mutableFields)
    }

    // MARK: - Soft Delete

    /// Marks the dog as inactive without removing the Firestore document.
    static func softDeleteDog(id: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("dogs").document(id).updateData([
            "is_active":  false,
            "updated_at": FieldValue.serverTimestamp()
        ])
    }
}
