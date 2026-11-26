# Bus App for iOS

The iOS app is a native SwiftUI client for the Spring Boot backend. The LTA
DataMall key remains on the backend and is never included in this project.

## Project structure

```text
BusApp/
├── App/                         App entry point and configuration
├── Core/API/                    Backend client and error handling
├── Core/Location/               Testable device-location provider
├── Core/Notifications/          One-off local-notification protocol and adapter
├── Core/Persistence/            Favourite-stop storage protocol and UserDefaults adapter
├── Features/BusArrivals/        Full arrivals plus shared stop-preview state and UI
├── Features/FavoriteBusStops/   Shared favourite state and SwiftUI views
├── Features/NearbyBusStops/     Nearby list/map models, state, formatting, and UI
├── Features/BusStopSearch/      Search model, state, and SwiftUI views
└── Resources/                   Application configuration
BusAppTests/                     Model, networking, and state tests
```

## Run locally

1. Start the backend from `../bus-backend` with `./gradlew bootRun`.
2. Open `BusApp.xcodeproj`.
3. Run the `BusApp` scheme on an iPhone Simulator.
4. The app opens on Nearby in Map mode. Allow location access, then swipe the
   bottom cards to browse stops and the four earliest next-service arrivals.
5. Switch to List when needed, or use Search to enter a stop code, landmark, or
   road name.
6. Tap a star to save a stop locally.
7. Use Favourites to open, delete, or reorder saved stops.
8. Tap a result from any tab to view live arrivals for that stop.
9. Tap a service’s bell and choose an available lead time to create a one-off
   reminder for the next displayed bus.

For Simulator testing, choose a simulated location from Xcode’s location
controls. The Nearby screen handles disabled, denied, and restricted location
access separately and offers a Settings shortcut when access was denied.
Map markers reuse the loaded nearby results, highlight favourites, and open a
stop card with its road, code, distance, favourite action, and arrival link.
After a meaningful map movement, Search This Area queries the existing nearby
endpoint around the visible centre without requesting the device location again.
The result markers update without moving the camera; only the scope button fits
the camera to the most recent result region.
Pure map-region and annotation values keep fitting and marker mapping testable
without requiring MapKit UI automation.

Nearby cards and Favourite rows use one shared `BusStopArrivalPreviewStore`.
The store coalesces requests, keeps fresh per-stop results in memory, and refreshes
visible previews about every 20 seconds. A pure builder selects one next arrival
per service, sorts services by that timestamp, and keeps the earliest four.

The Search, Nearby, Favourites, and arrival screens share one observable
favourites ViewModel. Its storage dependency is a protocol, while the app uses a
UserDefaults implementation that persists the ordered stop list as JSON.

The detail screen loads `GET /api/v1/arrivals/{stopCode}` through the backend,
supports pull-to-refresh, and refreshes automatically about every 20 seconds
while it is visible. It shows up to three predictions per service, including
arrival time, passenger load, wheelchair accessibility, and bus type.

The reminder planner snapshots the first displayed prediction and schedules a
`UNCalendarNotificationTrigger` with `repeats` set to `false`. It never follows
later buses automatically. A deterministic stop/service identifier means a new
choice replaces the existing pending reminder instead of creating duplicates.
Permission, planning, scheduling, pending-reminder restoration, cancellation,
and the current time are separated behind testable types.

Debug builds use `http://localhost:8080`, while Release builds use
`https://bus-backend-ykuw.onrender.com` and authenticate with `X-App-Token`.

Create the ignored local configuration before running a Release build:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Replace the placeholder in `Secrets.xcconfig` with the same `APP_API_TOKEN`
configured in Render. A hexadecimal token generated with
`openssl rand -hex 32` is safe to use directly. If an existing base64 token
contains `//`, rotate it in Render because `//` begins an xcconfig comment. For
local Debug development on a physical iPhone, set `LOCAL_BACKEND_HOST` in the
same file to the Mac's local-network address. Simulator development can keep
`localhost`.

Select the shared **BusApp Hosted** scheme to run the Release configuration
against Render. Use the normal **BusApp** scheme for local Debug development.

The iOS app never talks to LTA DataMall directly and does not contain an LTA
account key.

## Home Screen widget

Save a stop in the app, then add **Favourite Stop Arrivals** from the Home
Screen widget gallery. Long-press the widget and choose **Edit Widget** to
select a favourite. Small shows up to two services and medium shows up to four.
Tap the arrow to request fresh estimates, or tap the widget body to open the
stop's live arrivals in the app.

The widget shows estimated arrival times and the snapshot's last update time.
iOS schedules automatic refreshes. Estimates expire after five minutes, and
the widget can show a recent cached snapshot if a refresh fails. Manual
requests for the same stop have a short cooldown.

For a device build, the signing team must have the
`group.com.jannicesuciptono.BusApp` App Group enabled for both `BusApp` and
`BusWidget`. The widget uses the same Debug and Hosted backend settings as the
app. To check automatic refresh behaviour, test on a device outside the Xcode
debugger.
