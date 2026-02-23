# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**SteeleWalker** is an iOS app for optimizing dog walking schedules, logging walks, and tracking dog profiles with health and sensitivity data.

---

## Setup & Build Commands

### Prerequisites
- Xcode 15+ (check with `xcodebuild -version`)
- XcodeGen: `brew install xcodegen`
- Firebase CLI: `brew install firebase-cli`

### Generate and Build

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Open the project in Xcode
open SteeleWalker.xcodeproj

# Build from command line (requires GoogleService-Info.plist in SteeleWalker/)
xcodebuild -scheme SteeleWalker -configuration Debug build

# Run on simulator or device (from Xcode)
# Cmd+R in Xcode after selecting simulator/device
```

### Firebase Setup
```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy composite indexes
firebase deploy --only firestore:indexes

# Start Firebase emulator (for DEBUG builds)
firebase emulators:start
```

---

## Project Architecture

### Directory Structure
- **Auth/** — `AuthViewModel.swift`: Manages Firebase auth state, Google/Apple sign-in, user document creation
- **Models/** — Firestore data models (Codable, Identifiable); most have documented Firestore schema as comments
- **Models/Enums/** — `DogSize`, `DogHealthCondition`, `DogSensitivity`, `ScheduleType`, `ScheduledWalkStatus`
- **Services/** — Static utility classes that handle all Firestore CRUD operations
  - `DogService`, `UserService`, `WalkLogService`, `WalkingScheduleService`, `ScheduledWalkService`
- **Views/** — SwiftUI views; `WelcomeView` (login), `ContentView` (main app)
- **Seeds/** — `BreedSeed.swift`: Populates 74 breed documents


### How to Add a New Feature

1. **create a ticket** using instructions from (.cursor/commands/create-issue.md)
2. **plan scope** using (.cursor/commands/create-plan.md)
3. **analyze implementation approach** review impacted code using (.cursor/commands/explore.md)
4. **implement changes** implement changes in accordance to (.cursor/commands/execute.md)
5. **debug and validate** share debug instructions or ways to determine build success

---

## Dependencies

Managed via Swift Package Manager (SPM) in `project.yml`:
- **Firebase iOS SDK** (≥ 10.0.0): FirebaseAuth, FirebaseFirestore
- **Google Sign-In for iOS** (≥ 7.0.0): GoogleSignIn, GoogleSignInSwift

---

## Tips for Development

- **Service functions are async/throws**: Always use `async try` when calling them
- **Firestore queries should respect user isolation**: Services typically filter by `user_id` to avoid exposing other users' data
- **Models are immutable by default**: Use `let` for all properties. Create new instances for updates.
- **@MainActor is enforced**: ViewModels must run on the main thread; Services can run off-thread and are safe for concurrent calls
- **Breed reference data is immutable**: The `Breed` collection is seeded once; avoid modifying it in Services

---

## MCP Integrations

Linear for issue tracking via MCP server. Issues can be referenced in commits and PRs.

---

## Notes on Configuration Files

- **project.yml**: XcodeGen specification. Modify to add new SPM packages or build settings.
- **.firebaserc**: Firebase project alias (one alias per line or JSON)
- **firestore.rules**: Security rules for Firestore collections
- **firestore.indexes.json**: Composite index definitions for efficient queries
- **GoogleService-Info.plist**: Firebase config (auto-downloaded from Firebase Console; not in source control)
