# SteeleWalker REST API Contract

**Version:** 1.0
**Status:** Design Document (No implementation)
**Last Updated:** 2026-02-23
**Scope:** Internal services only (recommendation engine, scheduled background jobs)

---

## Overview

This document defines the REST API for server-side operations in SteeleWalker. The iOS client continues to read/write Firestore directly via existing service classes for all client-initiated CRUD operations. This API is exclusively for internal backend services:

1. **Recommendation engine** — generates optimal walk times and attaches weather data
2. **Scheduled background jobs** — trigger bulk generation or housekeeping tasks

The API is hosted as **Firebase Cloud Functions** with HTTP triggers and is authenticated via Firebase Admin SDK ID token verification.

---

## Architecture

### Why REST over GraphQL?

The existing service layer maps 1:1 to REST routes. There is no nested query complexity that justifies GraphQL overhead for an internal-only API. REST is simpler to deploy and maintain as Cloud Functions.

### Why Firebase Cloud Functions?

Natural fit given the existing Firebase infrastructure:
- Admin SDK natively verifies Firebase ID tokens
- Direct access to Firestore in the same project
- Serverless scaling aligns with low-traffic internal operations

### Caller Boundaries

| Caller | Method | Collections |
|--------|--------|-------------|
| **iOS Client** | Direct Firestore SDK | `users`, `dogs`, `walk_logs`, `scheduled_walks`, `walking_schedules`, `breeds` |
| **Recommendation Engine** | REST API (this doc) | Reads: `walking_schedules`; Writes: `scheduled_walks` (with `weather_snapshot`) |
| **Background Jobs** | REST API (this doc) | Reads: various; Writes: `scheduled_walks` |

### Firestore Rules Unchanged

Client-side Firestore security rules remain unchanged. This API introduces **no new rule relaxations**:
- All `scheduled_walks` writes are still gated by `request.auth.uid == resource.data.user_id`
- All `walking_schedules` reads are still gated by the same rule
- The server verifies the requesting user's identity via ID token before operating on Firestore

---

## Authentication

### Token Format

```
Authorization: Bearer <Firebase ID Token>
```

### Verification Flow

1. Client calls API endpoint with `Authorization: Bearer <token>` header
2. Server uses Firebase Admin SDK to verify the token
3. Admin SDK returns the decoded `uid` from the token claims
4. Server extracts `user_id` and proceeds with identity-verified operations
5. If token is invalid or expired, return `401 Unauthorized`

### Example Header

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjEyMyJ9.eyJzdWIiOiJ1c2VyLWFiYzEyMyIsImlhdCI6MTcwOTY4MTIwMH0...
```

---

## Endpoints

### 1. POST /scheduled-walks/generate

**Purpose:** Generate `ScheduledWalk` instances from user's `WalkingSchedule` templates.

Mirrors the recommendation engine's core operation: for each day in the date range, read the matching `WalkingSchedule` template (weekday or weekend) and create `ScheduledWalk` documents with `status: pending`.

#### Request

```json
{
  "userId": "user-abc123",
  "startDate": "2026-02-23",
  "endDate": "2026-03-09"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | string | Yes | Firebase Auth UID of the user |
| `startDate` | string | Yes | Start date (inclusive) in `YYYY-MM-DD` format |
| `endDate` | string | Yes | End date (inclusive) in `YYYY-MM-DD` format |

#### Response

**200 OK**

```json
{
  "created": 14,
  "scheduledWalkIds": [
    "walk-001",
    "walk-002",
    "walk-003",
    ...
  ],
  "message": "Generated 14 scheduled walk instances"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `created` | integer | Count of successfully created documents |
| `scheduledWalkIds` | array of strings | Firestore document IDs of created `ScheduledWalk` instances |
| `message` | string | Human-readable confirmation |

#### Error Responses

| Status | Code | Body | Reason |
|--------|------|------|--------|
| 400 | `INVALID_REQUEST` | `{ "error": "startDate must be in YYYY-MM-DD format" }` | Malformed date |
| 401 | `UNAUTHORIZED` | `{ "error": "Invalid or expired token" }` | Invalid/expired bearer token |
| 403 | `FORBIDDEN` | `{ "error": "Token uid does not match userId in request" }` | User identity mismatch |
| 404 | `NOT_FOUND` | `{ "error": "No WalkingSchedule templates found for user" }` | User has no schedules configured |
| 500 | `INTERNAL_ERROR` | `{ "error": "Firestore write failed" }` | Database error |

#### Firestore Operations

**Reads:**
- `walking_schedules` collection: all documents where `user_id == userId`
- Determines which template (weekday or weekend) applies to each date in `[startDate, endDate]`

**Writes:**
- `scheduled_walks` collection: creates one document per walk slot per day
- Document structure:
  ```firestore
  {
    "id":               "walk-abc123",          // auto-assigned
    "user_id":          "user-abc123",          // from request
    "schedule_id":      "user-abc123_weekday",  // from template
    "date":             "2026-02-23",           // YYYY-MM-DD
    "preferred_time":   "07:00",                // HH:mm from WalkSlot
    "duration_minutes": 30,                     // from WalkSlot
    "walk_order":       1,                      // from WalkSlot
    "status":           "pending",              // ScheduledWalkStatus
    "created_at":       Timestamp.now(),        // server-set
    "updated_at":       Timestamp.now(),        // server-set
    "weather_snapshot": null                    // filled by /weather endpoint
  }
  ```

#### Idempotency

The endpoint is **idempotent** within a single date range:
- If called twice with identical `userId`, `startDate`, `endDate`, the second call recognizes existing documents and returns the same result without duplication
- Implementation: check existence before write; use Firestore transaction if needed to prevent race conditions

#### Notes

- Does **not** overwrite or delete existing `ScheduledWalk` documents
- If a walk for a given date/walkOrder already exists, skip it
- Respects weekday vs. weekend boundaries (uses actual calendar dates)
- Returns only the IDs of **newly created** documents (not pre-existing ones)

---

### 2. POST /scheduled-walks/:id/weather

**Purpose:** Attach a `WeatherSnapshot` to an existing `ScheduledWalk` document.

Called by the recommendation engine after fetching Tomorrow.io data for the walk's date/time window.

#### Request

```http
POST /scheduled-walks/walk-abc123/weather
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "temperatureF": 72.5,
  "feelsLikeF": 70.0,
  "humidity": 65,
  "windSpeedMph": 8.5,
  "precipProbability": 10,
  "precipType": null,
  "weatherCode": 1000,
  "conditionText": "Clear",
  "uvIndex": 5,
  "capturedAt": "2026-02-23T14:30:00Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `temperatureF` | number | Yes | Actual temperature in °F |
| `feelsLikeF` | number | Yes | "Feels like" temperature in °F |
| `humidity` | integer | Yes | Relative humidity, 0–100 |
| `windSpeedMph` | number | Yes | Wind speed in mph |
| `precipProbability` | integer | Yes | Precipitation probability, 0–100 |
| `precipType` | string or null | Yes | One of: `"rain"`, `"snow"`, `"freezing_rain"`, `"ice_pellets"`, or `null` |
| `weatherCode` | integer | Yes | Tomorrow.io weather code (e.g., 1000 = Clear, 4001 = Rain, 8000 = Thunderstorm) |
| `conditionText` | string | Yes | Human-readable condition (e.g., `"Clear"`, `"Rain"`, `"Thunderstorm"`) |
| `uvIndex` | integer | Yes | UV index, 0–11+ |
| `capturedAt` | string (ISO 8601) | Yes | Timestamp when data was fetched from Tomorrow.io |

#### Response

**200 OK**

```json
{
  "id": "walk-abc123",
  "updated": true,
  "message": "Weather snapshot attached to scheduled walk"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Firestore document ID of the updated `ScheduledWalk` |
| `updated` | boolean | `true` if update was successful |
| `message` | string | Confirmation message |

#### Error Responses

| Status | Code | Body | Reason |
|--------|------|------|--------|
| 400 | `INVALID_REQUEST` | `{ "error": "temperatureF is required" }` | Missing or invalid field |
| 401 | `UNAUTHORIZED` | `{ "error": "Invalid or expired token" }` | Invalid/expired bearer token |
| 403 | `FORBIDDEN` | `{ "error": "User does not own this ScheduledWalk" }` | Attempting to modify another user's walk |
| 404 | `NOT_FOUND` | `{ "error": "ScheduledWalk not found" }` | Walk ID does not exist |
| 500 | `INTERNAL_ERROR` | `{ "error": "Firestore update failed" }` | Database error |

#### Firestore Operations

**Reads:**
- `scheduled_walks/{id}` document: confirm it exists and belongs to the authenticated user

**Writes:**
- `scheduled_walks/{id}`: updates the `weather_snapshot` nested object and `updated_at` timestamp
- Update payload:
  ```firestore
  {
    "weather_snapshot": {
      "temperature_f":      72.5,
      "feels_like_f":       70.0,
      "humidity":           65,
      "wind_speed_mph":     8.5,
      "precip_probability": 10,
      "precip_type":        null,
      "weather_code":       1000,
      "condition_text":     "Clear",
      "uv_index":           5,
      "captured_at":        Timestamp.fromDate(...)
    },
    "updated_at": Timestamp.now()
  }
  ```

#### Idempotency

Calling with identical data is safe; the update is idempotent. Subsequent calls overwrite with the same values.

#### Notes

- Does **not** modify any other fields of the `ScheduledWalk`
- Firestore rules remain in effect: the Admin SDK enforces user isolation
- The `weather_snapshot` in `ScheduledWalk` is immutable once set; re-calling this endpoint overwrites the previous snapshot (rare in production, but safe)

---

## Error Handling

### Common Error Response Format

All error responses follow this shape:

```json
{
  "error": "Human-readable error message",
  "code": "ERROR_CODE",
  "details": {}
}
```

### HTTP Status Codes

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 400 | Bad request (invalid input, malformed payload) |
| 401 | Unauthorized (missing or invalid token) |
| 403 | Forbidden (user lacks permission for resource) |
| 404 | Not found (resource does not exist) |
| 500 | Internal server error (Firestore, network, etc.) |

---

## Deployment & Environment

### Cloud Functions Layout

```
functions/
├── src/
│   ├── generateScheduledWalks.ts
│   ├── attachWeather.ts
│   ├── auth.ts                     # Token verification utilities
│   ├── firestore.ts                # Firestore helpers
│   └── index.ts                    # Main entry point
├── package.json
└── tsconfig.json
```

### Language & Runtime

- **Language:** TypeScript
- **Runtime:** Node.js 18 (Firebase default)
- **SDK:** Firebase Admin SDK (`firebase-admin@latest`)

### Deployment Command

```bash
firebase deploy --only functions
```

### Environment Variables

None required — functions authenticate via the default service account in the Firebase project.

---

## Security Considerations

### User Isolation

All endpoints verify that the request bearer token's `uid` matches the `userId` in the request or the document owner in Firestore. This enforces strict per-user operation boundaries.

### No Privilege Escalation

The API does not expose endpoints for:
- Creating users
- Deleting users
- Modifying Firestore rules
- Accessing the Breed reference collection (read-only via client)

### Firestore Rules Remain the Sole Authority

Even though the Cloud Functions use the Admin SDK (which bypasses Firestore rules), the API enforces identity checks in code. In practice:
- Functions decode the ID token → extract `uid`
- Functions query/write Firestore with explicit `user_id` filters
- If token is valid but the `uid` doesn't match the resource, the operation is rejected

This defense-in-depth approach ensures that stolen Admin SDK credentials cannot be exploited without a valid user token.

---

## Rate Limiting

Not defined in this contract. Implement Cloud Functions rate limiting or Cloud Armor policies as a separate operational decision.

---

## Monitoring & Logging

Functions should log:
- **Info:** successful endpoint calls (user ID, operation, counts)
- **Warn:** retryable failures (Firestore transient errors)
- **Error:** auth failures, invalid inputs, unrecoverable errors

Use Firebase Cloud Logging for all logs; accessible via Firebase Console.

---

## Future Extensions

Endpoints not in scope for NEH-37, but anticipated:

- `POST /walking-schedules/import` — bulk import schedules from external source
- `DELETE /scheduled-walks/range` — delete all walks in a date range
- `PATCH /scheduled-walks/:id/status` — update status without modifying weather

These can be added as separate tickets once the foundation is in place.

---

## Summary

| Endpoint | Method | Auth | Collections | Purpose |
|----------|--------|------|-------------|---------|
| `/scheduled-walks/generate` | POST | Bearer token | R: `walking_schedules`; W: `scheduled_walks` | Recommendation engine generates walk instances |
| `/scheduled-walks/:id/weather` | POST | Bearer token | R: `scheduled_walks`; W: `scheduled_walks` | Attach weather snapshot to a walk |

This REST API exclusively serves internal backend operations. The iOS client continues to use Firestore SDK for all user-initiated CRUD and queries, preserving simplicity and eliminating unnecessary API hops for interactive features.
