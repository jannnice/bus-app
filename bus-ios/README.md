# Bus App for iOS

The iOS app is a native SwiftUI client for the Spring Boot backend. The LTA
DataMall key remains on the backend and is never included in this project.

## Project structure

```text
BusApp/
├── App/                         App entry point and configuration
├── Core/API/                    Backend client and error handling
├── Features/BusStopSearch/      Search model, state, and SwiftUI views
└── Resources/                   Application configuration
BusAppTests/                     Model, networking, and state tests
```

## Run locally

1. Start the backend from `../bus-backend` with `./gradlew bootRun`.
2. Open `BusApp.xcodeproj`.
3. Run the `BusApp` scheme on an iPhone Simulator.
4. Enter a stop code, landmark, or road name and press Search.

`BackendBaseURL` in `BusApp/Resources/Info.plist` defaults to
`http://localhost:8080`. Replace it with your Mac's local network address when
running on a physical iPhone.
