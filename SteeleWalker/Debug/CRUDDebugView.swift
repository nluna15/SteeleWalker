#if DEBUG
import SwiftUI
import FirebaseFirestore

struct CRUDDebugView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var log: [String] = []
    @State private var debugDogId: String?
    @State private var debugScheduledWalkId: String?
    @State private var debugWalkLogId: String?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - User
                Section("User") {
                    Button("Fetch User") { run("Fetch User") {
                        let u = try await UserService.fetchUser(uid: uid)
                        return u.name
                    }}
                    Button("Update Name") { run("Update Name") {
                        try await UserService.updateUser(uid: uid, fields: [
                            "name": "Debug User",
                            "updated_at": FieldValue.serverTimestamp()
                        ])
                        return "ok"
                    }}
                }

                // MARK: - Dog
                Section("Dog") {
                    Button("Add Dog") { run("Add Dog") {
                        let id = try await DogService.addDog(
                            userId: uid,
                            name: "Debug Dog",
                            breedIds: ["breed_123"],
                            size: "medium"
                        )
                        debugDogId = id
                        return id
                    }}
                    Button("Fetch Dog") { run("Fetch Dog") {
                        guard let dogId = debugDogId else { throw TestError.noDogId }
                        let dog = try await DogService.fetchDog(id: dogId)
                        return dog.name
                    }}
                    Button("Fetch Dogs List") { run("Fetch Dogs List") {
                        let dogs = try await DogService.fetchDogs(userId: uid)
                        return "found \(dogs.count)"
                    }}
                    Button("Update Dog") { run("Update Dog") {
                        guard let dogId = debugDogId else { throw TestError.noDogId }
                        try await DogService.updateDog(id: dogId, fields: [
                            "name": "Updated Debug Dog"
                        ])
                        return "ok"
                    }}
                    Button("Soft Delete Dog") { run("Soft Delete Dog") {
                        guard let dogId = debugDogId else { throw TestError.noDogId }
                        try await DogService.softDeleteDog(id: dogId)
                        return "ok"
                    }}
                }

                // MARK: - WalkingSchedule
                Section("WalkingSchedule") {
                    Button("Set Weekday Schedule") { run("Set Weekday Schedule") {
                        let slots = [WalkSlotInput(preferredTime: "09:00", durationMinutes: 30, walkOrder: 1)]
                        try await WalkingScheduleService.setSchedule(
                            userId: uid,
                            scheduleType: "weekday",
                            walksPerDay: 1,
                            slots: slots
                        )
                        return "ok"
                    }}
                    Button("Set Weekday Again (idempotent)") { run("Set Weekday Again") {
                        let slots = [WalkSlotInput(preferredTime: "10:00", durationMinutes: 45, walkOrder: 1)]
                        try await WalkingScheduleService.setSchedule(
                            userId: uid,
                            scheduleType: "weekday",
                            walksPerDay: 1,
                            slots: slots
                        )
                        return "ok"
                    }}
                    Button("Fetch Schedules") { run("Fetch Schedules") {
                        let schedules = try await WalkingScheduleService.fetchSchedules(userId: uid)
                        return "found \(schedules.count)"
                    }}
                    Button("Delete Weekday") { run("Delete Weekday") {
                        try await WalkingScheduleService.deleteSchedule(userId: uid, scheduleType: "weekday")
                        return "ok"
                    }}
                }

                // MARK: - ScheduledWalk
                Section("ScheduledWalk") {
                    Button("Add ScheduledWalk") { run("Add ScheduledWalk") {
                        let id = try await ScheduledWalkService.addScheduledWalk(
                            userId: uid,
                            scheduleId: "sched_debug",
                            date: "2025-02-20",
                            preferredTime: "09:00",
                            durationMinutes: 30,
                            walkOrder: 1
                        )
                        debugScheduledWalkId = id
                        return id
                    }}
                    Button("Fetch ScheduledWalk by Date") { run("Fetch by Date") {
                        let walks = try await ScheduledWalkService.fetchScheduledWalks(
                            userId: uid,
                            date: "2025-02-20"
                        )
                        return "found \(walks.count)"
                    }}
                    Button("Skip Walk") { run("Skip Walk") {
                        guard let walkId = debugScheduledWalkId else { throw TestError.noWalkId }
                        try await ScheduledWalkService.skipScheduledWalk(id: walkId)
                        return "ok"
                    }}
                    Button("Delete Walk") { run("Delete Walk") {
                        guard let walkId = debugScheduledWalkId else { throw TestError.noWalkId }
                        try await ScheduledWalkService.deleteScheduledWalk(id: walkId)
                        return "ok"
                    }}
                }

                // MARK: - WalkLog
                Section("WalkLog") {
                    Button("Add Ad-hoc Log") { run("Add Ad-hoc Log") {
                        let id = try await WalkLogService.addWalkLog(
                            userId: uid,
                            date: "2025-02-20",
                            dogIds: ["dog_123"]
                        )
                        debugWalkLogId = id
                        return id
                    }}
                    Button("Add Linked Log (batch)") { run("Add Linked Log") {
                        guard let walkId = debugScheduledWalkId else { throw TestError.noWalkId }
                        let id = try await WalkLogService.addWalkLog(
                            userId: uid,
                            date: "2025-02-20",
                            dogIds: ["dog_456"],
                            scheduledWalkId: walkId
                        )
                        debugWalkLogId = id
                        return id
                    }}
                    Button("Fetch Logs by Date") { run("Fetch Logs by Date") {
                        let logs = try await WalkLogService.fetchWalkLogs(userId: uid, date: "2025-02-20")
                        return "found \(logs.count)"
                    }}
                    Button("Delete Linked Log (batch revert)") { run("Delete Linked Log") {
                        guard let logId = debugWalkLogId else { throw TestError.noLogId }
                        guard let walkId = debugScheduledWalkId else { throw TestError.noWalkId }
                        try await WalkLogService.deleteWalkLog(id: logId, scheduledWalkId: walkId)
                        return "ok"
                    }}
                }

                // MARK: - Log
                Section("Log") {
                    Button(role: .destructive) {
                        log = []
                    } label: {
                        Text("Clear Log")
                    }

                    ForEach(log, id: \.self) { entry in
                        Text(entry)
                            .font(.caption)
                            .monospaced()
                    }
                }
            }
            .navigationTitle("CRUD Debug")
        }
    }

    private var uid: String {
        auth.currentUser?.uid ?? "unknown"
    }

    private func run(_ label: String, _ body: @escaping () async throws -> String) {
        Task {
            do {
                let result = try await body()
                log.insert("✓ \(label): \(result)", at: 0)
            } catch {
                log.insert("✗ \(label): \(error)", at: 0)
            }
        }
    }
}

enum TestError: LocalizedError {
    case noDogId
    case noWalkId
    case noLogId

    var errorDescription: String? {
        switch self {
        case .noDogId: return "No dog ID stored from previous operation"
        case .noWalkId: return "No walk ID stored from previous operation"
        case .noLogId: return "No log ID stored from previous operation"
        }
    }
}

#endif
