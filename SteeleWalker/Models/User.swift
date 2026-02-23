import Foundation

// MARK: - AuthProvider

/// OAuth provider used to sign in.
enum AuthProvider: String, Codable {
    case google = "google"
    case apple  = "apple"
}

// MARK: - LocationType

/// Whether the user's home-base location came from GPS or was entered manually.
enum LocationType: String, Codable {
    case gps    = "gps"
    case manual = "manual"
}

// MARK: - Location

/// Polymorphic home-base location.
///
/// Firestore document shape (GPS):
/// ```json
/// { "type": "gps", "lat": 37.77, "long": -122.41 }
/// ```
/// Firestore document shape (manual):
/// ```json
/// { "type": "manual", "zip_code": "94103", "city": "San Francisco" }
/// ```
struct Location: Codable {
    let type: LocationType

    // GPS fields — present only when type == .gps
    let latitude:  Double?
    let longitude: Double?

    // Manual entry fields — present only when type == .manual
    let zipCode: String?
    let city:    String?

    enum CodingKeys: String, CodingKey {
        case type
        case latitude  = "lat"
        case longitude = "long"
        case zipCode   = "zip_code"
        case city
    }

    /// Convenience constructor for GPS-based location.
    static func gps(latitude: Double, longitude: Double) -> Location {
        Location(type: .gps, latitude: latitude, longitude: longitude, zipCode: nil, city: nil)
    }

    /// Convenience constructor for manually entered location.
    static func manual(zipCode: String, city: String) -> Location {
        Location(type: .manual, latitude: nil, longitude: nil, zipCode: zipCode, city: city)
    }
}

// MARK: - User

/// Firestore collection: `users`
/// Document ID: Firebase Auth UID (`auth.uid`)
///
/// Top-level; one document per authenticated user.
struct User: Codable, Identifiable {
    /// Firestore document ID — equals Firebase Auth UID.
    let id: String

    let name: String

    /// Which OAuth provider was used to sign in.
    let authProvider: AuthProvider

    /// The provider's opaque user identifier (e.g. Google sub, Apple user ID).
    let authProviderId: String

    /// Home-base location for walk recommendations. `nil` if the user has not
    /// granted location permission and has not entered it manually.
    let location: Location?

    /// User's email address. Captured on first Apple Sign-In (Apple provides it only once).
    let email: String?

    /// Whether the user has opted into push notifications.
    let notificationsEnabled: Bool

    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case authProvider         = "auth_provider"
        case authProviderId       = "auth_provider_id"
        case location
        case email
        case notificationsEnabled = "notifications_enabled"
        case createdAt            = "created_at"
        case updatedAt            = "updated_at"
    }
}
