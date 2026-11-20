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

The Simulator uses `http://localhost:8080`, configured as `BackendBaseURL` in
`BusApp/Resources/Info.plist`. For a physical iPhone, change that value to your
Mac's local network address, such as `http://192.168.1.10:8080`, and ensure the
Mac and iPhone are on the same network.

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
