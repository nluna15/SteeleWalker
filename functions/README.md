# SteeleWalker Cloud Functions

Firebase Cloud Functions (TypeScript, Node.js 18) powering the SteeleWalker backend.

## Setup

### Prerequisites

- Node.js 18+
- Firebase CLI: `npm install -g firebase-tools`
- Firebase project with Firestore and Authentication enabled

### Install dependencies

```bash
cd functions
npm install
```

### Build

```bash
npm run build
```

---

## Environment Variables

### Tomorrow.io API Key (required)

The weather forecast endpoint proxies requests to Tomorrow.io. The API key is stored as a Firebase Function secret (never committed to source).

**Set the secret:**

```bash
firebase functions:secrets:set TOMORROW_IO_API_KEY
```

You will be prompted to enter the key value. Obtain an API key from [https://app.tomorrow.io](https://app.tomorrow.io).

**Access in code:** `process.env.TOMORROW_IO_API_KEY`

**Local development (emulator):** Create a `.env.local` file in `functions/` (gitignored):

```
TOMORROW_IO_API_KEY=your_dev_key_here
```

---

## Endpoints

### GET /weatherForecastHourly

Returns current conditions + 48 hours of hourly forecast for a lat/lon location.

**Auth:** Firebase ID token in `Authorization: Bearer <token>` header.

**Query params:** `lat` (required), `lon` (required), `units` (optional: `"imperial"` default or `"metric"`)

**Emulator:**

```bash
curl "http://localhost:5001/<project-id>/us-central1/weatherForecastHourly?lat=34.05&lon=-118.24" \
  -H "Authorization: Bearer <id-token>"
```

See `API_CONTRACT.md` for full request/response documentation.

---

## Local Development

### Start the emulator

```bash
# From project root
firebase emulators:start
```

Services available:
- Auth emulator: `http://localhost:9099`
- Firestore emulator: `http://localhost:8080`
- Functions emulator: `http://localhost:5001`
- Emulator UI: `http://localhost:4000`

### Run tests

```bash
cd functions
npm test
```

---

## Deployment

```bash
firebase deploy --only functions
```

Make sure the `TOMORROW_IO_API_KEY` secret is set before deploying (see above).

---

## Project Structure

```
functions/
├── src/
│   ├── index.ts              # HTTP trigger exports (entry point)
│   ├── auth.ts               # Firebase ID token verification
│   ├── firestore.ts          # Firestore admin client (used by future endpoints)
│   └── weather/
│       ├── types.ts          # WeatherEntry, HourlyEntry, ForecastResponse DTOs
│       ├── tomorrowClient.ts # Tomorrow.io Timelines API client + field mapping
│       ├── forecast.ts       # GET /weather/forecast/hourly handler
│       └── __tests__/
│           └── tomorrowClient.test.ts
├── package.json
├── tsconfig.json
└── README.md
```
