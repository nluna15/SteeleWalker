# SteeleWalker

An iOS app for managing dog walking schedules, logging walks, and tracking dog profiles with health and sensitivity data.

## Tech Stack

- **iOS 16+** — SwiftUI
- **Backend** — Firebase (Firestore + Authentication)
- **Auth** — Google Sign-In, Apple Sign-In
- **Project generation** — XcodeGen
- **Dependencies** — Swift Package Manager

---

## Prerequisites

| Tool | Install |
|------|---------|
| Xcode 15+ | Mac App Store |
| XcodeGen | `brew install xcodegen` |
| Firebase CLI | `brew install firebase-cli` |

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/nluna15/SteeleWalker.git
cd SteeleWalker
```

### 2. Add your Firebase config

`GoogleService-Info.plist` is excluded from source control. You need to provide your own:

1. Go to the [Firebase Console](https://console.firebase.google.com) and open your project
2. Navigate to **Project Settings → Your apps → iOS app**
3. Download `GoogleService-Info.plist`
4. Place the file at `SteeleWalker/GoogleService-Info.plist`

### 3. Generate the Xcode project

```bash
xcodegen generate
```

This reads `project.yml` and produces `SteeleWalker.xcodeproj`.

### 4. Open in Xcode and resolve packages

```bash
open SteeleWalker.xcodeproj
```

Xcode will automatically fetch SPM dependencies (Firebase SDK, Google Sign-In). Wait for the package resolution to finish before building.

### 5. Build and run

Select a simulator or device and press **Cmd+R**.

---

## Firebase Setup

### Firestore Rules

Deploy the security rules from `firestore.rules`:

```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes

Deploy composite indexes from `firestore.indexes.json`:

```bash
firebase deploy --only firestore:indexes
```

### Seed Breed Data

The breed reference collection (`breeds`) is seeded at app launch via `SteeleWalker/Seeds/BreedSeed.swift`. Run the app once while authenticated to populate it. The seed is a no-op if documents already exist.

---

## Project Structure

```
SteeleWalker/
├── Auth/
│   └── AuthViewModel.swift       # Firebase auth, Google & Apple sign-in
├── Models/
│   ├── User.swift
│   ├── Dog.swift
│   ├── WalkLog.swift
│   ├── ScheduledWalk.swift
│   ├── WalkingSchedule.swift
│   ├── Breed.swift
│   └── Enums/                    # DogSize, DogHealthCondition, DogSensitivity, ScheduleType
├── Views/
│   ├── WelcomeView.swift         # Sign-in screen
│   └── ContentView.swift         # Main app screen
├── Seeds/
│   └── BreedSeed.swift           # 74 breeds + 15 mixed breed options
└── SteeleWalkerApp.swift         # App entry point
firestore.rules                   # Firestore security rules
firestore.indexes.json            # Composite indexes
project.yml                       # XcodeGen config
```

## Firestore Collections

| Collection | Description |
|---|---|
| `users` | User profiles (auth UID as document ID) |
| `dogs` | Dog profiles linked to a user |
| `walking_schedules` | Recurring weekday/weekend walk templates |
| `scheduled_walks` | Individual walk instances generated from templates |
| `walk_logs` | Walk history entries |
| `breeds` | Read-only breed reference data (seeded by app) |

---

## Google Sign-In Configuration

In the Firebase Console, ensure your iOS app has the **Google Sign-In** OAuth client set up. The `GoogleService-Info.plist` you download will include the `REVERSED_CLIENT_ID` — this is registered as a URL scheme in `Info.plist` and is required for the sign-in redirect to work.
