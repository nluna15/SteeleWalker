import Foundation

/// Firestore collection: `dogs`
/// Document ID: auto-generated
/// FK: `user_id` → `users/{id}`
///
/// One user may own many dogs. Each dog document is a top-level document
/// (not a subcollection) so cross-user admin queries remain possible.
struct Dog: Codable, Identifiable {
    /// Firestore document ID.
    let id: String

    /// Owner's Firebase Auth UID — matches `users/{user_id}`.
    let userId: String

    let name: String

    /// Reference to a document in the `breeds` collection.
    let breedId: String

    /// Birth month (1–12). Optional — user may not know exact date.
    let birthMonth: Int?

    /// Birth year (e.g. 2019). Optional — user may not know exact date.
    let birthYear: Int?

    let weightLbs: Double?

    let size: DogSize

    /// URL to a profile photo stored in Firebase Storage. `nil` until the user
    /// uploads one.
    let photoUrl: String?

    /// Free-text allergy notes (e.g. "grass, bee stings").
    let allergyNotes: String?

    /// Free-text general health notes visible to the owner.
    let healthNotes: String?

    /// Enabled health condition keys — a subset of `DogHealthCondition` raw values.
    /// Stored as an array so future conditions can be added without a schema migration.
    /// Example: `["heart_condition", "arthritis"]`
    let healthConditions: [String]

    /// Enabled environmental sensitivity keys — a subset of `DogSensitivity` raw values.
    /// Example: `["rain", "extreme_heat"]`
    let sensitivities: [String]

    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId           = "user_id"
        case name
        case breedId          = "breed_id"
        case birthMonth       = "birth_month"
        case birthYear        = "birth_year"
        case weightLbs        = "weight_lbs"
        case size
        case photoUrl         = "photo_url"
        case allergyNotes     = "allergy_notes"
        case healthNotes      = "health_notes"
        case healthConditions = "health_conditions"
        case sensitivities
        case createdAt        = "created_at"
        case updatedAt        = "updated_at"
    }

    // MARK: - Typed accessors

    /// Decoded health conditions from raw string keys stored in Firestore.
    var typedHealthConditions: [DogHealthCondition] {
        healthConditions.compactMap { DogHealthCondition(rawValue: $0) }
    }

    /// Decoded sensitivities from raw string keys stored in Firestore.
    var typedSensitivities: [DogSensitivity] {
        sensitivities.compactMap { DogSensitivity(rawValue: $0) }
    }
}
