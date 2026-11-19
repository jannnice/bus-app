import SwiftUI

struct NearbyBusStopsView: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel: NearbyBusStopsViewModel

    private let arrivalAPIClient: any BusArrivalAPIClient
    private let distanceFormatter: DistanceFormatter
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init(
        apiClient: any NearbyBusStopAPIClient & BusArrivalAPIClient,
        locationProvider: any UserLocationProvider,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel,
        distanceFormatter: DistanceFormatter = DistanceFormatter()
    ) {
        arrivalAPIClient = apiClient
        self.distanceFormatter = distanceFormatter
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
        _viewModel = State(
            initialValue: NearbyBusStopsViewModel(
                apiClient: apiClient,
                locationProvider: locationProvider
            )
        )
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Nearby Stops")
        }
        .task {
            guard viewModel.state == .idle else {
                return
            }
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .requestingLocation:
            ProgressView("Finding your location...")

        case .loadingStops:
            ProgressView("Finding nearby bus stops...")

        case .loaded:
            List(viewModel.busStops) { busStop in
                HStack(spacing: 8) {
                    NavigationLink {
                        BusArrivalView(
                            busStop: busStop.busStop,
                            apiClient: arrivalAPIClient,
                            favoriteBusStopsViewModel: favoriteBusStopsViewModel
                        )
                    } label: {
                        NearbyBusStopRow(
                            busStop: busStop,
                            distanceFormatter: distanceFormatter
                        )
                    }

                    FavoriteToggleButton(
                        busStop: busStop.busStop,
                        viewModel: favoriteBusStopsViewModel
                    )
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load()
            }

        case .empty:
            ContentUnavailableView {
                Label("No Nearby Stops", systemImage: "location.slash")
            } description: {
                Text("No bus stops were found within 500 metres of your location.")
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }

        case .permissionDenied:
            ContentUnavailableView {
                Label("Location Access Off", systemImage: "location.slash")
            } description: {
                Text("Allow Bus App to use your location to find nearby stops.")
            } actions: {
                Button("Open Settings") {
                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
            }

        case .permissionRestricted:
            ContentUnavailableView {
                Label("Location Restricted", systemImage: "location.slash")
            } description: {
                Text("Location access is restricted by this device’s settings.")
            }

        case let .failed(message):
            ContentUnavailableView {
                Label("Couldn’t Find Nearby Stops", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

#Preview {
    NearbyBusStopsView(
        apiClient: PreviewNearbyAPIClient(),
        locationProvider: PreviewLocationProvider(),
        favoriteBusStopsViewModel: .preview()
    )
}

private struct PreviewNearbyAPIClient: NearbyBusStopAPIClient, BusArrivalAPIClient {
    func nearbyBusStops(
        latitude: Double,
        longitude: Double,
        radiusMeters: Int,
        limit: Int
    ) async throws -> [NearbyBusStop] {
        [
            NearbyBusStop(
                stopCode: "01012",
                roadName: "Victoria St",
                description: "Hotel Grand Pacific",
                latitude: 1.29685,
                longitude: 103.853,
                distanceMeters: 85
            )
        ]
    }

    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        BusArrivalResponse(stopCode: stopCode, services: [])
    }
}

@MainActor
private struct PreviewLocationProvider: UserLocationProvider {
    func requestLocation() async throws -> UserLocation {
        UserLocation(latitude: 1.2968, longitude: 103.853)
    }
}
