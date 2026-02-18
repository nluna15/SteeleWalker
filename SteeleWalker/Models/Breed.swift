import Foundation

/// Firestore collection: `breeds`
/// Document ID: auto-generated
///
/// Reference table for dog breeds. Seeded at app launch; used to power the
/// breed typeahead in the dog creation flow. Stored as a top-level collection
/// so it can be queried independently of any user.
///
/// Future: breed-specific weather tolerance thresholds can be added as fields
/// without schema migration (e.g. `heat_tolerance`, `cold_tolerance`).
struct Breed: Codable, Identifiable {
    /// Firestore document ID.
    let id: String

    /// Human-readable breed name shown in the typeahead (e.g. "Golden Retriever",
    /// "Labrador Mix", "Mixed - General").
    let name: String

    /// Soft-delete flag — set to `false` to hide a breed without removing it,
    /// preserving referential integrity with existing dog documents.
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isActive = "is_active"
    }
}
