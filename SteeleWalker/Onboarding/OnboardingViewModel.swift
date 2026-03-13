import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Supporting Types

struct DogDraft: Identifiable {
    var id = UUID()
    var name = ""
    var breedIds: [String] = []
    var breedDisplayNames: [String] = []
    var size: DogSize = .medium
    var ageText: String = ""
    var isUnderOneYear: Bool = false
    var mobilities: Set<DogMobility> = [.noRestrictions]
    var mobilityNote = ""
    var sensitivities: Set<DogSensitivity> = []

    var computedBirthYear: Int? {
        let currentYear = Calendar.current.component(.year, from: Date())
        if isUnderOneYear { return currentYear }
        guard let age = Int(ageText), age > 0 else { return nil }
        return currentYear - age
    }
}

enum WalkTime: String, CaseIterable, Identifiable {
    case morning   = "morning"
    case midday    = "midday"
    case afternoon = "afternoon"
    case evening   = "evening"

    var id: String { rawValue }

    var preferredTime: String {
        switch self {
        case .morning:   return "07:00"
        case .midday:    return "12:00"
        case .afternoon: return "15:00"
        case .evening:   return "18:00"
        }
    }

    var displayName: String {
        switch self {
        case .morning:   return "Morning"
        case .midday:    return "Midday"
        case .afternoon: return "Afternoon"
        case .evening:   return "Evening"
        }
    }

    var systemImage: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .midday:    return "sun.max.fill"
        case .afternoon: return "sun.horizon.fill"
        case .evening:   return "moon.stars.fill"
        }
    }
}

// MARK: - OnboardingViewModel

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: Step tracking
    @Published var currentStep: Int = 0

    // MARK: Step 1 — Dogs
    @Published var dogCount: Int = 1 {
        didSet { updateDogCount(dogCount) }
    }
    @Published var dogs: [DogDraft] = [DogDraft()]
    private var dogCache: [Int: [DogDraft]] = [:]

    // MARK: Step 2 — Walk Routine
    @Published var walksPerDay: Int = 2
    @Published var durationMinutes: Int = 30
    @Published var selectedTimes: Set<WalkTime> = []

    // MARK: Step 3 — Location
    @Published var useGPS: Bool = false
    @Published var locationText: String = ""
    @Published var gpsLatitude: Double?
    @Published var gpsLongitude: Double?

    // MARK: Async state
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var submissionError: Bool = false
    @Published var isOnboardingComplete: Bool = false

    // Called directly after a successful submit — set by OnboardingContainerView
    var onComplete: (() -> Void)?

    // MARK: - Dog count management

    func updateDogCount(_ newCount: Int) {
        // Cache current dog data
        dogCache[dogs.count] = dogs

        // Restore from cache or pad with new drafts
        if let cached = dogCache[newCount] {
            dogs = cached
        } else if newCount > dogs.count {
            let extra = (dogs.count..<newCount).map { _ in DogDraft() }
            dogs = dogs + extra
        } else {
            dogs = Array(dogs.prefix(newCount))
        }
    }

    // MARK: - Validation

    var isStep1Valid: Bool {
        dogs.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && !$0.breedIds.isEmpty && ($0.isUnderOneYear || (Int($0.ageText) ?? 0) > 0) }
    }

    var isStep2Valid: Bool {
        !selectedTimes.isEmpty
    }

    var isStep3Valid: Bool {
        if useGPS {
            return gpsLatitude != nil && gpsLongitude != nil
        } else {
            return !locationText.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - Submit

    func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            guard let userId = Auth.auth().currentUser?.uid, !userId.isEmpty else {
                throw NSError(
                    domain: "OnboardingViewModel",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "You must be signed in to complete setup. Please sign in and try again."]
                )
            }

            let db = Firestore.firestore()
            let batch = db.batch()

            // 1. Queue dog writes — pre-generate refs so IDs are stable across retries
            for dog in dogs {
                let ref = db.collection("dogs").document()
                var data: [String: Any] = [
                    "id":                ref.documentID,
                    "user_id":           userId,
                    "name":              dog.name,
                    "breed_ids":         dog.breedIds,
                    "size":              dog.size.rawValue,
                    "health_conditions": Array(dog.mobilities).flatMap(\.healthConditionKeys),
                    "sensitivities":     dog.sensitivities.map(\.rawValue),
                    "is_active":         true,
                    "birth_year":        dog.computedBirthYear ?? Calendar.current.component(.year, from: Date()),
                    "created_at":        FieldValue.serverTimestamp(),
                    "updated_at":        FieldValue.serverTimestamp()
                ]
                if dog.mobilities.contains(.other) && !dog.mobilityNote.isEmpty {
                    data["health_notes"] = dog.mobilityNote
                }
                batch.setData(data, forDocument: ref)
            }

            // 2. Queue walk schedule write
            let scheduleDocId = "\(userId)_\(ScheduleType.weekday.rawValue)"
            let scheduleRef = db.collection("walking_schedules").document(scheduleDocId)
            let sortedTimes = WalkTime.allCases.filter { selectedTimes.contains($0) }
            let slots: [[String: Any]] = sortedTimes.enumerated().map { index, time in
                [
                    "preferred_time":   time.preferredTime,
                    "duration_minutes": durationMinutes,
                    "walk_order":       index + 1
                ]
            }
            batch.setData([
                "id":             scheduleDocId,
                "user_id":        userId,
                "schedule_type":  ScheduleType.weekday.rawValue,
                "walks_per_day":  walksPerDay,
                "slots":          slots,
                "updated_at":     FieldValue.serverTimestamp()
            ], forDocument: scheduleRef, merge: true)

            // 2b. Queue weekend schedule (mirrors weekday for all-week coverage)
            let weekendDocId = "\(userId)_\(ScheduleType.weekend.rawValue)"
            let weekendRef = db.collection("walking_schedules").document(weekendDocId)
            batch.setData([
                "id":             weekendDocId,
                "user_id":        userId,
                "schedule_type":  ScheduleType.weekend.rawValue,
                "walks_per_day":  walksPerDay,
                "slots":          slots,
                "updated_at":     FieldValue.serverTimestamp()
            ], forDocument: weekendRef, merge: true)

            // 3. Queue location write
            var locationDict: [String: Any]
            if useGPS, let lat = gpsLatitude, let lon = gpsLongitude {
                locationDict = ["type": "gps", "lat": lat, "long": lon]
            } else {
                locationDict = ["type": "manual"]
                let trimmed = locationText.trimmingCharacters(in: .whitespaces)
                if trimmed.range(of: #"^\d{5}$"#, options: .regularExpression) != nil {
                    locationDict["zip_code"] = trimmed
                } else {
                    locationDict["city"] = trimmed
                }
            }
            let userRef = db.collection("users").document(userId)
            batch.setData(["location": locationDict], forDocument: userRef, merge: true)

            // 4. Commit — atomic: all writes succeed or all fail, no partial state
            try await batch.commit()

            // 5. Mark onboarding complete only after successful commit
            UserDefaults.standard.set(true, forKey: "onboardingComplete_\(userId)")
            isOnboardingComplete = true
            onComplete?()

        } catch is CancellationError {
            // Task was cancelled — silently reset without showing an error to the user.
        } catch {
            errorMessage = error.localizedDescription
            submissionError = true
        }
    }

#if DEBUG
    func skipForDebug() {
        guard let userId = Auth.auth().currentUser?.uid, !userId.isEmpty else { return }
        UserDefaults.standard.set(true, forKey: "onboardingComplete_\(userId)")
        isOnboardingComplete = true
        onComplete?()
    }
#endif
}
