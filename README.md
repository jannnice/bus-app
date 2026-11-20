# Singapore Bus App

A learning-focused Singapore bus application with a native SwiftUI frontend and
a Java and Spring Boot backend.

The backend acts as a secure boundary between the iOS application and LTA DataMall. It keeps the LTA account key off the device, validates requests, transforms LTA-specific responses into a stable application API, and briefly caches live arrivals.

## Repository structure

```text
bus-app/
├── bus-backend/    Java 21 and Spring Boot backend
└── bus-ios/        SwiftUI iOS application
```

## Current iOS features

- Bus-stop search by code, landmark, or road name
- Nearby bus stops using the device location, shown as a distance-ordered list or MapKit map
- Selectable map markers with favourite highlighting and live-arrival navigation
- Clear location permission, restricted-access, empty, and retry states
- Locally saved favourite stops with deletion and custom ordering
- Live arrivals after selecting a search result
- Up to three predictions per service with load, accessibility, and bus type
- Pull-to-refresh and automatic refresh about every 20 seconds while visible
- One-off local reminders for the next displayed bus, with 1, 3, 5, or 10-minute lead times
- Typed async networking using `URLSession`
- Loading, empty-results, empty-service, and backend-error states
- Configurable backend URL with no LTA key stored on the device
- Model, networking, and view-model tests

## Current backend features

- `GET /api/v1/arrivals/{stopCode}` for live bus arrivals
- Optional `serviceNo` filtering for a single bus service
- Bus-stop search by code, landmark, or road name
- Nearby bus stops ordered by distance from the user
- Typed LTA DataMall client and response models
- Automatic pagination across the complete LTA bus-stop dataset
- Five-digit bus stop validation
- Connection and read timeouts for upstream requests
- Stable JSON errors for invalid requests, configuration, and upstream failures
- Separate 20-second arrival and 24-hour bus-stop caches
- Actuator health endpoint
- Unit, controller, HTTP client, context, and caching tests

## Requirements

- Java 21
- Xcode 27 or later
- An LTA DataMall Account Key

Gradle does not need to be installed separately because the repository includes the Gradle wrapper.

## Configure the LTA key

Request an Account Key from the [LTA DataMall API access form](https://datamall.lta.gov.sg/content/datamall/en/request-for-api.html).

Expose the key as an environment variable before starting the backend:

```bash
export LTA_ACCOUNT_KEY="your-account-key"
```

Never commit the real account key or place it in the iOS application.

## Run the backend

```bash
cd bus-backend
./gradlew bootRun
```

Request arrivals for a bus stop:

```bash
curl http://localhost:8080/api/v1/arrivals/83139
```

Request arrivals for one service at that stop:

```bash
curl "http://localhost:8080/api/v1/arrivals/83139?serviceNo=15"
```

Search for bus stops by stop code, landmark, or road name:

```bash
curl "http://localhost:8080/api/v1/bus-stops?query=grand&limit=20"
```

Find stops within 500 metres of a location, nearest first:

```bash
curl "http://localhost:8080/api/v1/bus-stops/nearby?latitude=1.2968&longitude=103.853&radiusMeters=500&limit=20"
```

Search results contain the stop code, road name, description, latitude, and
longitude. Nearby results also contain `distanceMeters`.

Check application health:

```bash
curl http://localhost:8080/actuator/health
```

## Prepare and deploy the backend

The backend includes a multi-stage Java 21 `Dockerfile` and a Render Blueprint
for a Singapore-hosted web service. Local development remains unchanged and does
not require an app token.

The `production` Spring profile protects every `/api/v1/**` request with:

- An `X-App-Token` header, configured through `APP_API_TOKEN`
- A process-wide fixed-window rate limit, configured through
  `APP_REQUESTS_PER_MINUTE` and defaulting to 120 requests per minute

The health endpoint remains public so the hosting platform can monitor the
service. A production process fails at startup when `APP_API_TOKEN` is missing
or shorter than 32 characters.

Generate a token and save it in a password manager. Do not commit it:

```bash
openssl rand -hex 32
```

To exercise the production configuration locally:

```bash
cd bus-backend
export LTA_ACCOUNT_KEY="your-account-key"
export APP_API_TOKEN="your-random-token-of-at-least-32-characters"
SPRING_PROFILES_ACTIVE=production ./gradlew bootRun
```

Protected requests must include the token:

```bash
curl \
  -H "X-App-Token: $APP_API_TOKEN" \
  http://localhost:8080/api/v1/arrivals/83139
```

To deploy with Render:

1. Push the repository to GitHub.
2. In Render, create a Blueprint from the repository's `render.yaml`.
3. Enter `LTA_ACCOUNT_KEY` and `APP_API_TOKEN` when prompted. Use the same app
   token later when configuring the iOS client.
4. Confirm that `GET /actuator/health` returns `{"status":"UP"}`.
5. Confirm that an API request without `X-App-Token` returns `401`, and a request
   with the header reaches LTA DataMall.

The Blueprint starts on Render's free plan. Change `plan` in `render.yaml` or in
the Render dashboard when an always-on instance is needed.

## Error responses

Every handled API error uses the same shape, so clients can make decisions using
the stable `code` while still showing a useful `message`:

```json
{
  "code": "INVALID_REQUEST",
  "message": "stopCode must contain exactly 5 digits",
  "timestamp": "2026-11-16T14:30:00Z",
  "path": "/api/v1/arrivals/not-a-stop"
}
```

Current error codes are:

| HTTP status | Code | Meaning |
| --- | --- | --- |
| `400` | `INVALID_REQUEST` | A path, query, or request-body value failed validation |
| `401` | `UNAUTHORIZED` | The production API token is missing or invalid |
| `429` | `RATE_LIMITED` | The production request limit was exceeded |
| `502` | `LTA_UNAVAILABLE` | LTA DataMall could not be reached or rejected the upstream request |
| `503` | `LTA_NOT_CONFIGURED` | The backend has no LTA account key configured |

## Run the tests

```bash
cd bus-backend
./gradlew test
```

Automated tests use fixture data and a mock HTTP server. They do not require an LTA key or call the live DataMall API.

## Run the iOS app

1. Start the backend on port `8080`.
2. Open `bus-ios/BusApp.xcodeproj` in Xcode.
3. Select an iPhone Simulator and run the `BusApp` scheme.
4. Use the Search tab to find a stop such as `83139`, `grand`, or `Victoria`.
5. Use the Nearby tab to allow location access and see stops within 500 metres.
   Switch between List and Map to browse the same nearby results.
6. Tap a star on a search result, nearby stop, or arrival screen to save it.
7. Use the Favourites tab to open, delete, or reorder saved stops.
8. Tap a result in any tab to see its live bus services and next arrivals.
9. Tap the bell beside a service to schedule a one-off reminder for its next
   displayed bus. The app asks for notification permission only when needed.

The Simulator can use a simulated location from Xcode’s location controls. On a
physical iPhone, iOS asks for location access only when the Nearby tab needs it.
If access was denied, the Nearby screen links to the app’s Settings page.

The Nearby map fits the user and returned stops on screen. Tap a marker to see
the stop name, road, code, and distance, then open live arrivals or toggle its
favourite status. After moving the map, tap **Search This Area** to load stops
within 500 metres of the new map centre without changing the current camera
position. The scope button explicitly fits the most recent results after panning.

Favourites are encoded as JSON and stored locally in the app’s UserDefaults.
They do not require an account, backend endpoint, or LTA credential.

The arrivals screen refreshes while it is visible and can also be refreshed by
pulling down. Arrival times from the backend include their time-zone offset;
the app decodes them as absolute dates and displays `Arr`, whole minutes, or an
em dash when no prediction is available.

Arrival reminders are local, non-repeating notifications based on the estimate
shown when the reminder is created. They do not subscribe to the service or
automatically schedule reminders for later buses. Creating another reminder for
the same stop and service replaces its pending reminder, and an active reminder
can be cancelled from the same bell button.

Debug builds use `http://localhost:8080`. Release builds use the hosted backend
at `https://bus-backend-ykuw.onrender.com` and send an app token with every API
request.

Before running a Release build, create the ignored local secrets file:

```bash
cp bus-ios/Config/Secrets.xcconfig.example bus-ios/Config/Secrets.xcconfig
```

Open `Secrets.xcconfig` and replace the placeholder with the same
`APP_API_TOKEN` configured in Render. The file is ignored by Git and must never
be committed. Hexadecimal tokens generated by the command above are safe to use
directly in an Xcode configuration file. If an existing base64 token contains
`//`, rotate it to a hexadecimal token in Render because `//` begins an xcconfig
comment.

In Xcode, select the shared **BusApp Hosted** scheme to install and run the
Release configuration against Render. Continue using the normal **BusApp**
scheme for local Debug development.

For Debug development on a physical iPhone, also set `LOCAL_BACKEND_HOST` in
`Secrets.xcconfig` to the Mac's local-network address, such as `192.168.1.10`,
and ensure the Mac and iPhone are on the same network. The Simulator can keep
the default `localhost` value. Supplying the app token to a local backend is
harmless; local development does not require it.

Run the iOS tests from Xcode with Product > Test.

## Architecture

```text
iOS app
   |
   v
BusArrivalController
   |
   v
BusArrivalService ----> Caffeine cache
   |
   v
LtaClient ----> LTA DataMall
   |
   v
LtaArrivalMapper ----> Public API response
```

Bus-stop requests follow a similar path: `BusStopController` asks
`BusStopService` to search the cached catalog, while `LtaBusStopClient`
downloads all DataMall pages when the 24-hour catalog cache needs refreshing.

The project is intentionally a modular monolith. Database persistence, Docker,
and deployment automation will be introduced incrementally as the project grows.
