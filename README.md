# Singapore Bus App

A learning-focused Singapore bus application with a native iOS frontend planned alongside a Java and Spring Boot backend.

The backend acts as a secure boundary between the iOS application and LTA DataMall. It keeps the LTA account key off the device, validates requests, transforms LTA-specific responses into a stable application API, and briefly caches live arrivals.

## Repository structure

```text
bus-app/
├── bus-backend/    Java 21 and Spring Boot backend
└── bus-ios/        Planned SwiftUI application
```

## Current backend features

- `GET /api/v1/arrivals/{stopCode}` for live bus arrivals
- Optional `serviceNo` filtering for a single bus service
- Typed LTA DataMall client and response models
- Five-digit bus stop validation
- Connection and read timeouts for upstream requests
- Stable JSON errors for invalid requests, configuration, and upstream failures
- 20-second in-memory Caffeine cache
- Actuator health endpoint
- Unit, controller, HTTP client, context, and caching tests

## Requirements

- Java 21
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

The project is intentionally a modular monolith. Database persistence, static bus-stop data, Docker, and deployment automation will be introduced incrementally as the project grows.
