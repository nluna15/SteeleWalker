# Paste this into Linear → New issue

**Title (copy exactly):**
```
Implement Firestore schema and Swift data models for dog walking app
```

**Description (paste everything below the line):**
---
## TL;DR
Set up the cloud database (Firestore) structure and iOS Swift models so the app can store users, dogs, walking schedules, and walk logs. All decisions from product discovery are captured as requirements below.

## Current state vs expected outcome
| Current | Expected |
|--------|----------|
| No database or models; only schema designed in discussion | Firestore collections + document structure + composite indexes defined and implemented |
| No Swift types for app data | Swift structs (Codable, iOS 16+) for all entities, organized for MVVM |
| Weather/recommendation logic not specified | Tomorrow.io as single weather source; recommendation logic deferred but data model supports it |

## Requirements (from chat decisions)

### Auth & user
- **Sign-in:** Google Sign-In + Sign in with Apple only (no email/password).
- **User fields:** name, auth_provider, auth_provider_id, location (GPS lat/long or manual zip_code + city), location_source, notifications_enabled, created_at, updated_at.
- **Location:** Home base from GPS (if permitted) or user-entered zip/city; no street address.

### Dogs
- **One user, many dogs.** Each dog: name, breed_id (FK to breed list), birth_month, birth_year, weight_lbs, size (small/medium/large/extra_large), photo_url, allergy_notes (free text), health_notes (free text).
- **Breed:** Curated list with typeahead; support mixed breeds at a high level (e.g. "Labrador Mix", "Mixed - General"). Stored in a reference table for future breed-specific weather logic.
- **Health:** Structured checkboxes (heart_condition, breathing_difficulty, low_energy, arthritis, recent_surgery, hip_issues, senior_mobility) + one open-ended health_notes field per dog. Health can change over time (editable).
- **Sensitivities:** Checklist per dog: rain, thunder_lightning, extreme_heat, extreme_cold, wind. Stored now; logic for how weather impacts each dog comes later.
- **Allergies:** Open-ended text per dog for now.

### Walking schedule
- **Owner-level schedule only** (all dogs share it). Separate weekday vs weekend schedules.
- **Per schedule:** multiple walk slots. Each slot: preferred_time, duration_minutes, walk_order.
- **Window:** User says "around 7am" → app treats as 60–90 min window; recommendation engine will pick optimal time within that (e.g. 7:23am). Different walks can have different lengths and times.

### Walk tracking
- **Single "started" action** per walk (no completion or GPS). One tap = "I started this walk" for all dogs together.
- **Walk log:** user_id, optional scheduled_walk_id, date, started_at. No route/distance/duration stored.

### Recommendations & weather
- **Recommendations:** Computed in the moment from weather + dog data + schedule; not stored. Show household (pack) recommendation and per-dog weather impact on tap.
- **Weather source:** Tomorrow.io only (weather + pollen + air quality). No Apple WeatherKit.
- **Breed/weather tolerance logic:** Not implemented yet; schema must support it later (breed reference table, dog-level sensitivities/health).

### Notifications
- Morning walks: notify the evening before.
- Afternoon/evening walks: notify ~1 hour before.
- notifications_enabled on user.

### Tech stack (locked)
- **Database:** Firestore (cloud).
- **UI:** SwiftUI.
- **Architecture:** MVVM.
- **Min iOS:** 16+.
- **Weather API:** Tomorrow.io.

### Out of scope (for this issue)
- Storing recommendation results or historical weather.
- Email/password auth.
- Social features, vet integrations.
- GPS route or walk completion tracking.
- Implementing recommendation or breed-tolerance logic (data model only).

## Relevant files / deliverables
- **Firestore:** Collection names, document ID strategy, field names, and composite index definitions (e.g. `firestore.indexes.json` or equivalent).
- **Swift:** `Models/` (or equivalent) with structs: `User`, `Breed`, `Dog`, `DogHealthCondition`, `DogSensitivity`, `WalkingSchedule`, `ScheduledWalk`, `WalkLog`; enums for condition_type, sensitivity_type, size, schedule_type; all Codable, iOS 16 compatible.
- **Docs:** Optional one-pager mapping schema tables → Firestore collections/documents and Swift types.

## Risk / notes
- **Indexes:** Define composite indexes up front for any query that filters/sorts by `user_id`, `dog_id`, `schedule_id`, or `date` to avoid "missing index" errors in production.
- **Auth:** Firestore security rules must scope reads/writes by `auth.uid` (or equivalent) once Firebase Auth (Google + Apple) is wired; can be a follow-up issue.
- **Breed list:** Need a seed list of breeds + mixed options for typeahead; can be a separate small task or included here.

## Labels (suggested)
- **Type:** Feature
- **Priority:** High (foundation for rest of app)
- **Effort:** Medium
