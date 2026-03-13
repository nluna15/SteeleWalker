import Foundation

@MainActor
class DogEditViewModel: ObservableObject {
    let dog: Dog

    @Published var name: String
    @Published var breedIds: [String]
    @Published var breedDisplayNames: [String]
    @Published var size: DogSize
    @Published var ageText: String
    @Published var isUnderOneYear: Bool
    @Published var mobilities: Set<DogMobility>
    @Published var mobilityNote: String
    @Published var sensitivities: Set<DogSensitivity>

    @Published var isSaving: Bool = false
    @Published var didSave: Bool = false
    @Published var isDeleting: Bool = false
    @Published var didDelete: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?

    init(dog: Dog) {
        self.dog = dog
        self.name = dog.name
        self.breedIds = dog.breedIds
        self.breedDisplayNames = dog.breedIds   // will be resolved via BreedSeed lookup
        self.size = dog.size
        // Derive age fields from birth year if available
        if let birthYear = dog.birthYear {
            let currentYear = Calendar.current.component(.year, from: Date())
            let age = currentYear - birthYear
            if age < 1 {
                self.ageText = ""
                self.isUnderOneYear = true
            } else {
                self.ageText = "\(age)"
                self.isUnderOneYear = false
            }
        } else {
            self.ageText = ""
            self.isUnderOneYear = false
        }
        // Derive mobilities from health conditions (can match multiple)
        let conditions = Set(dog.healthConditions)
        var derived: Set<DogMobility> = []
        if conditions.contains("recent_surgery") { derived.insert(.recovering) }
        if conditions.contains("senior_mobility") || conditions.contains("low_energy") { derived.insert(.seniorSlowerPace) }
        if conditions.contains("arthritis") || conditions.contains("hip_issues") { derived.insert(.jointMobility) }
        if conditions.contains("heart_condition") { derived.insert(.heartCondition) }
        if conditions.contains("breathing_difficulty") { derived.insert(.breathingIssues) }
        self.mobilities = derived.isEmpty ? [.noRestrictions] : derived
        self.mobilityNote = dog.healthNotes ?? ""
        self.sensitivities = Set(dog.sensitivities.compactMap { DogSensitivity(rawValue: $0) })

        // Resolve display names from seed for each stored breed ID
        self.breedDisplayNames = dog.breedIds.compactMap { id in
            BreedSeed.all.first(where: { $0.id == id })?.name
        }
    }

    func save() async {
        isSaving = true
        var fields: [String: Any] = [
            "name":              name,
            "breed_ids":         breedIds,
            "size":              size.rawValue,
            "health_conditions": Array(mobilities).flatMap(\.healthConditionKeys),
            "sensitivities":     sensitivities.map(\.rawValue),
            "birth_year":        isUnderOneYear ? Calendar.current.component(.year, from: Date()) : Calendar.current.component(.year, from: Date()) - (Int(ageText) ?? 0)
        ]
        if mobilities.contains(.other) && !mobilityNote.isEmpty {
            fields["health_notes"] = mobilityNote
        } else {
            fields["health_notes"] = NSNull()
        }

        do {
            try await DogService.updateDog(id: dog.id, fields: fields)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }

    func delete() async {
        isDeleting = true
        do {
            try await DogService.softDeleteDog(id: dog.id)
            didDelete = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isDeleting = false
    }
}
