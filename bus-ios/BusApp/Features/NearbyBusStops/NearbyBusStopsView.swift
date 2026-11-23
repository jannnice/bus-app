import SwiftUI

struct NearbyBusStopsView: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel: NearbyBusStopsViewModel

    private let arrivalAPIClient: any BusArrivalAPIClient
    private let distanceFormatter: DistanceFormatter
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    private let arrivalPreviewStore: BusStopArrivalPreviewStore

    init(
        apiClient: any NearbyBusStopAPIClient & BusArrivalAPIClient,
        locationProvider: any UserLocationProvider,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel,
        arrivalPreviewStore: BusStopArrivalPreviewStore? = nil,
        distanceFormatter: DistanceFormatter = DistanceFormatter()
    ) {
        arrivalAPIClient = apiClient
        self.distanceFormatter = distanceFormatter
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
        self.arrivalPreviewStore = arrivalPreviewStore
            ?? BusStopArrivalPreviewStore(apiClient: apiClient)
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if viewModel.state == .loaded,
                       viewModel.displayMode == .map {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await viewModel.load() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .disabled(viewModel.isSearchingMapArea)
                        }
                    }
                }
        }
        .task {
            guard viewModel.state == .idle else {
                return
            }
            await viewModel.load()
        }
        .alert("Map Search", isPresented: mapSearchMessageIsPresented) {
            Button("OK", role: .cancel) {
                viewModel.dismissMapSearchMessage()
            }
        } message: {
            Text(viewModel.mapSearchMessage ?? "The map search could not be completed.")
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
            loadedContent

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

    private var displayModeBinding: Binding<NearbyBusStopsDisplayMode> {
        Binding(
            get: { viewModel.displayMode },
            set: viewModel.setDisplayMode
        )
    }

    @ViewBuilder
    private var loadedContent: some View {
        VStack(spacing: 0) {
            Picker("Nearby stop view", selection: displayModeBinding) {
                Label("List", systemImage: "list.bullet")
                    .tag(NearbyBusStopsDisplayMode.list)
                Label("Map", systemImage: "map")
                    .tag(NearbyBusStopsDisplayMode.map)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch viewModel.displayMode {
            case .list:
                nearbyStopsList

            case .map:
                if let mapRegion = viewModel.mapRegion {
                    NearbyBusStopsMap(
                        busStops: viewModel.busStops,
                        region: mapRegion,
                        selectedBusStop: viewModel.selectedBusStop,
                        arrivalAPIClient: arrivalAPIClient,
                        favoriteBusStopsViewModel: favoriteBusStopsViewModel,
                        arrivalPreviewStore: arrivalPreviewStore,
                        distanceFormatter: distanceFormatter,
                        canSearchMapArea: viewModel.canSearchMapArea,
                        isSearchingMapArea: viewModel.isSearchingMapArea,
                        onSelect: viewModel.selectBusStop,
                        onVisibleCenterChange: viewModel.updateVisibleMapCenter,
                        onSearchMapArea: viewModel.searchPendingMapArea
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var nearbyStopsList: some View {
        if viewModel.busStops.isEmpty {
            ContentUnavailableView {
                Label("No Stops in This Area", systemImage: "map")
            } description: {
                Text("Move the map and search another area, or refresh from your location.")
            } actions: {
                Button("Refresh My Location") {
                    Task { await viewModel.load() }
                }
            }
        } else {
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
        }
    }

    private var mapSearchMessageIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.mapSearchMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissMapSearchMessage()
                }
            }
        )
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
