import Foundation

@MainActor
class WalkingPreferencesViewModel: ObservableObject {
    @Published var walksPerDay: Int = 2
    @Published var durationMinutes: Int = 30
    @Published var selectedTimes: Set<WalkTime> = [.morning]

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var didSave: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?

    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    var isValid: Bool { !selectedTimes.isEmpty }

    func load() async {
        isLoading = true
        do {
            let schedule = try await WalkingScheduleService.fetchSchedule(
                userId: userId,
                scheduleType: ScheduleType.weekday.rawValue
            )
            if let firstSlot = schedule.slots.first {
                durationMinutes = firstSlot.durationMinutes
            }
            walksPerDay = schedule.walksPerDay
            selectedTimes = Set(
                schedule.slots.compactMap { slot in
                    WalkTime.allCases.first { $0.preferredTime == slot.preferredTime }
                }
            )
        } catch {
            // No existing schedule is fine — use defaults
        }
        isLoading = false
    }

    func save() async {
        isSaving = true
        let sortedTimes = WalkTime.allCases.filter { selectedTimes.contains($0) }
        let slots: [WalkSlotInput] = sortedTimes.enumerated().map { index, time in
            WalkSlotInput(
                preferredTime:   time.preferredTime,
                durationMinutes: durationMinutes,
                walkOrder:       index + 1
            )
        }
        do {
            try await WalkingScheduleService.setSchedule(
                userId: userId,
                scheduleType: ScheduleType.weekday.rawValue,
                walksPerDay: walksPerDay,
                slots: slots
            )
            try await WalkingScheduleService.setSchedule(
                userId: userId,
                scheduleType: ScheduleType.weekend.rawValue,
                walksPerDay: walksPerDay,
                slots: slots
            )
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}
