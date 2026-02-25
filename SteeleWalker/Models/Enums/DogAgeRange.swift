import Foundation

/// Age range for a dog, used during onboarding when the exact birth year is unknown.
/// The `approximateBirthYear` converts each range to a year for Firestore storage.
enum DogAgeRange: String, CaseIterable {
    case puppy       = "puppy"
    case oneToThree  = "one_to_three"
    case threeToSeven = "three_to_seven"
    case senior      = "senior"

    var displayName: String {
        switch self {
        case .puppy:        return "Puppy (< 1 yr)"
        case .oneToThree:   return "1–3 years"
        case .threeToSeven: return "3–7 years"
        case .senior:       return "Senior (7+ yrs)"
        }
    }

    /// Approximate birth year derived from the midpoint of each range.
    var approximateBirthYear: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        switch self {
        case .puppy:        return currentYear
        case .oneToThree:   return currentYear - 2
        case .threeToSeven: return currentYear - 5
        case .senior:       return currentYear - 9
        }
    }
}
