# Bus App for iOS

The iOS app is a native SwiftUI client for the Spring Boot backend. The LTA
DataMall key remains on the backend and is never included in this project.

## Project structure

```text
BusApp/
├── App/                         App entry point and configuration
├── Core/API/                    Backend client and error handling
├── Core/Location/               Testable device-location provider
├── Core/Persistence/            Favourite-stop storage protocol and UserDefaults adapter
├── Features/BusArrivals/        Live-arrival models, state, formatting, and UI
├── Features/FavoriteBusStops/   Shared favourite state and SwiftUI views
├── Features/NearbyBusStops/     Nearby-stop models, state, formatting, and UI
├── Features/BusStopSearch/      Search model, state, and SwiftUI views
└── Resources/                   Application configuration
BusAppTests/                     Model, networking, and state tests
```

## Run locally

1. Start the backend from `../bus-backend` with `./gradlew bootRun`.
2. Open `BusApp.xcodeproj`.
3. Run the `BusApp` scheme on an iPhone Simulator.
4. In Search, enter a stop code, landmark, or road name and press Search.
5. In Nearby, allow location access to list stops within 500 metres.
6. Tap a star to save a stop locally.
7. Use Favourites to open, delete, or reorder saved stops.
8. Tap a result from any tab to view live arrivals for that stop.

For Simulator testing, choose a simulated location from Xcode’s location
controls. The Nearby screen handles disabled, denied, and restricted location
access separately and offers a Settings shortcut when access was denied.

The Search, Nearby, Favourites, and arrival screens share one observable
favourites ViewModel. Its storage dependency is a protocol, while the app uses a
UserDefaults implementation that persists the ordered stop list as JSON.

The detail screen loads `GET /api/v1/arrivals/{stopCode}` through the backend,
supports pull-to-refresh, and refreshes automatically about every 20 seconds
while it is visible. It shows up to three predictions per service, including
arrival time, passenger load, wheelchair accessibility, and bus type.

`BackendBaseURL` in `BusApp/Resources/Info.plist` defaults to
`http://localhost:8080`. Replace it with your Mac's local network address when
running on a physical iPhone.

The iOS app never talks to LTA DataMall directly and does not contain an LTA
account key.
