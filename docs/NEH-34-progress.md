# NEH-34 — Firestore Schema & Swift Data Models

**Overall Progress:** `100%`

---

## Steps

- [x] ✅ **Step 1: Xcode project scaffolding**
  - [x] ✅ SwiftUI app entry point (`SteeleWalkerApp.swift`)
  - [x] ✅ `project.yml` for xcodegen (iOS 16+, SPM deps)
  - [x] ✅ `Models/` + `Seeds/` directory structure
- [x] ✅ **Step 2: Firebase setup**
  - [x] ✅ `firebase.json` + `.firebaserc`
  - [x] ✅ `firestore.indexes.json` — composite indexes for user_id, dog_id, schedule_id, date
- [x] ✅ **Step 3: Firestore schema definition**
  - [x] ✅ `users`, `dogs`, `breeds`, `walking_schedules`, `scheduled_walks`, `walk_logs` — see models below
- [x] ✅ **Step 4: Swift enums**
  - [x] ✅ `DogSize`
  - [x] ✅ `ScheduleType`
  - [x] ✅ `DogHealthCondition`
  - [x] ✅ `DogSensitivity`
- [x] ✅ **Step 5: Swift models**
  - [x] ✅ `User` + `Location` (polymorphic)
  - [x] ✅ `Dog`
  - [x] ✅ `Breed`
  - [x] ✅ `WalkingSchedule` + `WalkSlot`
  - [x] ✅ `ScheduledWalk`
  - [x] ✅ `WalkLog`
- [x] ✅ **Step 6: Breed seed data**
  - [x] ✅ 63 breeds + 15 mixed options in `BreedSeed.swift`
