# Service Layer Documentation

## Overview

The SteeleWalker service layer provides a clean, type-safe interface to Firestore operations. All services follow these principles:

- **Static-only structs**: No instances; all functions are `static`.
- **Async/throws**: All functions are `async throws`. Callers use `try await`.
- **User-isolated queries**: Services filter by `user_id` to prevent unauthorized data access.
- **Thread-safe**: Services can be safely called from any thread; internal operations handle thread safety via Firestore SDK.
- **Timestamp auto-injection**: Some services automatically append `updated_at` on mutations.
- **Atomic operations**: `WalkLogService` uses `WriteBatch` to keep `walk_logs` and `scheduled_walks` in sync.

---

## UserService

**Firestore Collection**: `users`

### Functions

#### `fetchUser(uid: String) -> User`
Fetches a user document by UID.

**Parameters:**
- `uid`: Firebase Authentication UID

**Returns:** `User` model with email, location, and preferences.

**Behavior:** Decodes the entire user document as a `User` struct.

---

#### `updateUser(uid: String, fields: [String: Any]) -> Void`
Updates user fields using merge semantics (non-destructive patch).

**Parameters:**
- `uid`: Firebase Authentication UID
- `fields`: A dictionary of field updates, e.g. `["name": "John", "updated_at": FieldValue.serverTimestamp()]`

**Returns:** None (void).

**Design note:** `UserService.updateUser` does **not** auto-inject `updated_at`. Callers must supply the full `fields` dict with all desired changes, including timestamps if needed.

---

## DogService

**Firestore Collection**: `dogs`

### Functions

#### `addDog(...) -> String`
Creates a new dog document for a user.

**Parameters:**
- `userId`: User UID
- `name`: Dog's name
- `breedId`: Reference to a breed document ID (from `breeds` collection)
- `size`: Size category (e.g. `"small"`, `"medium"`, `"large"`)
- `healthConditions`: Array of health condition enum values (default: empty)
- `sensitivities`: Array of sensitivity enum values (default: empty)
- `birthMonth`: Optional month (1–12)
- `birthYear`: Optional year (e.g. 2020)
- `weightLbs`: Optional weight in pounds
- `photoUrl`: Optional Cloud Storage URL
- `allergyNotes`: Optional allergy text
- `healthNotes`: Optional health note text

**Returns:** Generated document ID (`String`).

**Behavior:**
- Generates a new document ID via `db.collection("dogs").document()`.
- Sets `is_active: true` automatically.
- Auto-injects `created_at` and `updated_at` via server timestamps.
- Optional fields are only added to the document if supplied.

---

#### `fetchDog(id: String) -> Dog`
Fetches a single dog by document ID.

**Parameters:**
- `id`: Dog document ID

**Returns:** `Dog` model.

---

#### `fetchDogs(userId: String) -> [Dog]`
Fetches all active dogs for a user, ordered by creation time.

**Parameters:**
- `userId`: User UID

**Returns:** Array of `Dog` models (filtered to `is_active == true`).

**Behavior:** Queries use composite filtering on `user_id` and `is_active`, then order by `created_at`.

---

#### `updateDog(id: String, fields: [String: Any]) -> Void`
Updates a dog document with caller-supplied fields.

**Parameters:**
- `id`: Dog document ID
- `fields`: Field updates (e.g. `["name": "Buddy"]`)

**Returns:** None (void).

**Design note:** `updated_at` is **always** appended automatically, even if not in `fields`.

---

#### `softDeleteDog(id: String) -> Void`
Marks a dog as inactive without deleting the Firestore document.

**Parameters:**
- `id`: Dog document ID

**Returns:** None (void).

**Behavior:** Sets `is_active: false` and updates `updated_at`. All `fetchDogs` queries ignore soft-deleted dogs.

---

## WalkingScheduleService

**Firestore Collection**: `walking_schedules`

### Design Notes

Document IDs are **deterministic** and derived as `"{userId}_{scheduleType}"` (e.g. `"user123_weekday"`). This enforces a one-per-type-per-user constraint at the Firestore level.

### Functions

#### `setSchedule(userId: String, scheduleType: String, slots: [[String: Any]]) -> Void`
Creates or updates a walking schedule using merge semantics.

**Parameters:**
- `userId`: User UID
- `scheduleType`: Schedule category (e.g. `"weekday"`, `"weekend"`)
- `slots`: Array of time slot objects (structure defined by UI/business logic)

**Returns:** None (void).

**Behavior:**
- Computes the deterministic document ID as `"{userId}_{scheduleType}"`.
- Uses `setData(..., merge: true)` so calling twice with the same user/type is idempotent.
- Auto-injects `updated_at` on each call.

---

#### `fetchSchedule(userId: String, scheduleType: String) -> WalkingSchedule`
Fetches a single schedule by user and type.

**Parameters:**
- `userId`: User UID
- `scheduleType`: Schedule category

**Returns:** `WalkingSchedule` model.

**Behavior:** Derives the deterministic document ID and fetches the document.

---

#### `fetchSchedules(userId: String) -> [WalkingSchedule]`
Fetches all schedules for a user (typically 2: weekday and weekend).

**Parameters:**
- `userId`: User UID

**Returns:** Array of `WalkingSchedule` models.

**Behavior:** Queries all documents with matching `user_id`.

---

#### `deleteSchedule(userId: String, scheduleType: String) -> Void`
Permanently deletes a schedule document.

**Parameters:**
- `userId`: User UID
- `scheduleType`: Schedule category

**Returns:** None (void).

**Behavior:** Derives the deterministic document ID and deletes it.

---

## ScheduledWalkService

**Firestore Collection**: `scheduled_walks`

### Functions

#### `addScheduledWalk(...) -> String`
Creates a new scheduled walk (an instance of a walking schedule on a specific date).

**Parameters:**
- `userId`: User UID
- `scheduleId`: Reference to a `walking_schedules` document ID
- `date`: Date string (e.g. `"2025-02-15"`)
- `preferredTime`: Time string (e.g. `"09:00"`)
- `durationMinutes`: Expected walk duration
- `walkOrder`: Ordinal position of this walk in the day's schedule

**Returns:** Generated document ID (`String`).

**Behavior:**
- Generates a new document ID.
- Sets `status: "pending"` automatically.
- Auto-injects `created_at` and `updated_at`.

---

#### `fetchScheduledWalk(id: String) -> ScheduledWalk`
Fetches a single scheduled walk by document ID.

**Parameters:**
- `id`: Scheduled walk document ID

**Returns:** `ScheduledWalk` model.

---

#### `fetchScheduledWalks(userId: String, date: String) -> [ScheduledWalk]`
Fetches all scheduled walks for a user on a specific date, ordered by `walk_order`.

**Parameters:**
- `userId`: User UID
- `date`: Date string (e.g. `"2025-02-15"`)

**Returns:** Array of `ScheduledWalk` models.

---

#### `fetchScheduledWalks(userId: String, startDate: String, endDate: String) -> [ScheduledWalk]`
Fetches all scheduled walks for a user within a date range (inclusive).

**Parameters:**
- `userId`: User UID
- `startDate`: Start date (inclusive)
- `endDate`: End date (inclusive)

**Returns:** Array of `ScheduledWalk` models.

**Behavior:** Queries use range filters on `date`.

---

#### `updateScheduledWalk(id: String, fields: [String: Any]) -> Void`
Updates a scheduled walk with caller-supplied fields.

**Parameters:**
- `id`: Scheduled walk document ID
- `fields`: Field updates

**Returns:** None (void).

**Design note:** `updated_at` is **always** appended automatically.

---

#### `deleteScheduledWalk(id: String) -> Void`
Permanently deletes a scheduled walk document.

**Parameters:**
- `id`: Scheduled walk document ID

**Returns:** None (void).

---

#### `skipScheduledWalk(id: String) -> Void`
Marks a scheduled walk as skipped without deleting the document.

**Parameters:**
- `id`: Scheduled walk document ID

**Returns:** None (void).

**Behavior:** Sets `status: "skipped"` and updates `updated_at`.

---

## WalkLogService

**Firestore Collection**: `walk_logs`

### Design Notes

`WalkLogService` uses **atomic WriteBatch** operations to keep `walk_logs` and `scheduled_walks` in sync. When a walk is logged for a `scheduled_walk`, the scheduled walk's status is immediately updated to `"completed"`. When a log is deleted, the status is reverted to `"pending"`.

### Functions

#### `addWalkLog(userId: String, date: String, dogIds: [String], scheduledWalkId: String? = nil) -> String`
Creates a new walk log.

**Parameters:**
- `userId`: User UID
- `date`: Walk date (e.g. `"2025-02-15"`)
- `dogIds`: Array of dog document IDs walked
- `scheduledWalkId`: Optional reference to a `scheduled_walks` document ID

**Returns:** Generated walk log document ID (`String`).

**Behavior:**
- Generates a new document ID.
- Auto-injects `started_at` via server timestamp.
- **If `scheduledWalkId` is provided**: Uses a WriteBatch to atomically:
  1. Create the walk log document.
  2. Update the referenced scheduled walk's status to `"completed"`.
- **If `scheduledWalkId` is nil**: Creates the log independently (unlinked walk).

---

#### `fetchWalkLogs(userId: String, date: String) -> [WalkLog]`
Fetches all walk logs for a user on a specific date.

**Parameters:**
- `userId`: User UID
- `date`: Date string (e.g. `"2025-02-15"`)

**Returns:** Array of `WalkLog` models.

---

#### `fetchWalkLogHistory(userId: String) -> [WalkLog]`
Fetches all walk logs for a user, newest first (for trend views).

**Parameters:**
- `userId`: User UID

**Returns:** Array of `WalkLog` models (ordered by `started_at` descending).

---

#### `deleteWalkLog(id: String, scheduledWalkId: String? = nil) -> Void`
Deletes a walk log.

**Parameters:**
- `id`: Walk log document ID
- `scheduledWalkId`: Optional reference to a linked `scheduled_walks` document

**Returns:** None (void).

**Behavior:**
- **If `scheduledWalkId` is provided**: Uses a WriteBatch to atomically:
  1. Delete the walk log.
  2. Revert the referenced scheduled walk's status back to `"pending"`.
- **If `scheduledWalkId` is nil**: Deletes the log independently.

---

## Supporting Models

### ScheduledWalkStatus

**File**: `Models/Enums/ScheduledWalkStatus.swift`

An enum representing the lifecycle state of a scheduled walk.

```swift
enum ScheduledWalkStatus: String, Codable {
    case pending   = "pending"
    case completed = "completed"
    case skipped   = "skipped"
}
```

**States:**
- `pending`: Scheduled walk is due but not yet started.
- `completed`: Walk was logged via `WalkLogService.addWalkLog`.
- `skipped`: Walk was explicitly marked as skipped via `ScheduledWalkService.skipScheduledWalk`.

---

### WeatherSnapshot

**File**: `Models/WeatherSnapshot.swift`

A denormalized weather reading from Tomorrow.io, embedded in both `ScheduledWalk` and `WalkLog` documents. Fields are chosen to map directly to `DogSensitivity` cases.

**Fields:**
- `temperatureF`: Actual temperature in °F.
- `feelsLikeF`: Apparent ("feels like") temperature in °F.
- `humidity`: Relative humidity, 0–100.
- `windSpeedMph`: Wind speed in mph.
- `precipProbability`: Precipitation probability, 0–100.
- `precipType`: Precipitation type (`"rain"`, `"snow"`, `"freezing_rain"`, `"ice_pellets"`, or `nil`).
- `weatherCode`: Tomorrow.io code (e.g. 1000 = Clear, 4001 = Rain, 8000 = Thunderstorm).
- `conditionText`: Human-readable label (e.g. `"Clear"`, `"Rain"`, `"Thunderstorm"`).
- `uvIndex`: UV index (0–11+).
- `capturedAt`: Timestamp when data was fetched.

**Design note:** Weather is **denormalized** on both `ScheduledWalk` and `WalkLog` so that trend queries (e.g. last 14 days of walk logs) require a single collection scan with no joins.

**Storage note:** Services do **not** currently auto-fetch or auto-inject weather. Callers supply weather data via the `fields` dict when updating `ScheduledWalk` or `WalkLog`.

---

## Cross-Cutting Patterns

### Auto-Injection of `updated_at`

- `DogService.updateDog`: Always appends `updated_at: FieldValue.serverTimestamp()`.
- `ScheduledWalkService.updateScheduledWalk`: Always appends `updated_at: FieldValue.serverTimestamp()`.
- `UserService.updateUser`: Does **not** auto-inject; callers supply the full `fields` dict.
- `WalkingScheduleService.setSchedule`: Always appends `updated_at: FieldValue.serverTimestamp()`.

### Atomic WriteBatch Operations

- `WalkLogService.addWalkLog`: If `scheduledWalkId` is provided, uses WriteBatch to create the log **and** mark the walk as completed in one operation.
- `WalkLogService.deleteWalkLog`: If `scheduledWalkId` is provided, uses WriteBatch to delete the log **and** revert the walk status to pending in one operation.

This ensures `walk_logs` and `scheduled_walks` never diverge.

### Soft Deletion

- `DogService.softDeleteDog`: Marks as `is_active: false` instead of deleting. All read queries filter to `is_active == true`.
- `ScheduledWalkService.skipScheduledWalk`: Marks as `status: "skipped"` instead of deleting; preserves history.

### Deterministic Document IDs

- `WalkingScheduleService`: Uses `"{userId}_{scheduleType}"` as the document ID, enforcing one schedule per type per user.
- All other services generate random IDs via `db.collection(...).document()`.

---

## Usage Examples

### Creating a Dog

```swift
let dogId = try await DogService.addDog(
    userId: user.id,
    name: "Buddy",
    breedId: "labrador_retriever",
    size: "large",
    healthConditions: ["hip_dysplasia"],
    sensitivities: ["extreme_heat"]
)
```

### Fetching and Updating a Dog

```swift
let dog = try await DogService.fetchDog(id: dogId)
try await DogService.updateDog(id: dogId, fields: ["name": "Buddy Jr"])
```

### Creating a Walking Schedule

```swift
let slots = [
    ["day": "Monday", "time": "09:00", "duration_minutes": 30],
    ["day": "Tuesday", "time": "14:00", "duration_minutes": 45]
]
try await WalkingScheduleService.setSchedule(
    userId: user.id,
    scheduleType: "weekday",
    slots: slots
)
```

### Creating a Scheduled Walk

```swift
let scheduledWalkId = try await ScheduledWalkService.addScheduledWalk(
    userId: user.id,
    scheduleId: "user123_weekday",
    date: "2025-02-15",
    preferredTime: "09:00",
    durationMinutes: 30,
    walkOrder: 1
)
```

### Logging a Walk and Marking It Complete

```swift
let logId = try await WalkLogService.addWalkLog(
    userId: user.id,
    date: "2025-02-15",
    dogIds: ["dog1", "dog2"],
    scheduledWalkId: scheduledWalkId  // Atomically updates status to "completed"
)
```

### Deleting a Walk Log and Reverting Status

```swift
try await WalkLogService.deleteWalkLog(id: logId, scheduledWalkId: scheduledWalkId)
// Atomically deletes the log and reverts the walk status back to "pending"
```

---

## Testing & Debugging

All services are designed for straightforward unit testing:
1. Mock Firestore instance (or use Firebase Emulator).
2. Call service functions with test data.
3. Verify returned values or document state.

For manual testing, use the debug view (if available) to smoke-test each service function.
