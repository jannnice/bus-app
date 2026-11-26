import SwiftUI
import WidgetKit

struct BusAppRootView: View {
    private enum Tab { case nearby, search, favorites }

    @Environment(\.scenePhase) private var scenePhase
    let apiClient: BackendAPIClient
    let favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    @State private var arrivalPreviewStore: BusStopArrivalPreviewStore
    @State private var selectedTab: Tab = .nearby
    @State private var favoritePath: [BusStop] = []
    @State private var lastWidgetReload = Date()

    init(
        apiClient: BackendAPIClient,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    ) {
        self.apiClient = apiClient
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
        _arrivalPreviewStore = State(
            initialValue: BusStopArrivalPreviewStore(apiClient: apiClient)
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NearbyBusStopsView(
                apiClient: apiClient,
                locationProvider: CoreLocationProvider(),
                favoriteBusStopsViewModel: favoriteBusStopsViewModel,
                arrivalPreviewStore: arrivalPreviewStore
            )
            .tabItem {
                Label("Nearby", systemImage: "location")
            }
            .tag(Tab.nearby)

            BusStopSearchView(
                apiClient: apiClient,
                favoriteBusStopsViewModel: favoriteBusStopsViewModel
            )
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            FavoriteBusStopsView(
                apiClient: apiClient,
                viewModel: favoriteBusStopsViewModel,
                arrivalPreviewStore: arrivalPreviewStore,
                path: $favoritePath
            )
            .tabItem {
                Label("Favourites", systemImage: "star")
            }
            .tag(Tab.favorites)
        }
        .onOpenURL(perform: openWidgetLink)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { reloadWidgetIfArrivalsChanged() }
        }
        .alert(
            "Favourites Unavailable",
            isPresented: favoriteErrorIsPresented
        ) {
            Button("OK", role: .cancel) {
                favoriteBusStopsViewModel.dismissError()
            }
        } message: {
            Text(favoriteErrorMessage)
        }
    }

    private func openWidgetLink(_ url: URL) {
        guard let route = BusWidgetLink(url: url) else { return }
        switch route {
        case .favorites:
            favoritePath = []
        case .arrivals(let code):
            let stop = favoriteBusStopsViewModel.busStops.first { $0.stopCode == code }
            favoritePath = stop.map { [$0] } ?? []
        }
        selectedTab = .favorites
    }

    private func reloadWidgetIfArrivalsChanged() {
        guard let data = BusWidgetData.open(), favoriteBusStopsViewModel.busStops.contains(where: {
            guard let snapshot = data.appSnapshot(for: $0.stopCode) else { return false }
            return snapshot.fetchedAt > lastWidgetReload && !snapshot.isExpired(at: .now)
        }) else { return }

        lastWidgetReload = .now
        WidgetCenter.shared.reloadTimelines(ofKind: BusWidgetData.widgetKind)
    }

    private var favoriteErrorIsPresented: Binding<Bool> {
        Binding(
            get: {
                if case .failed = favoriteBusStopsViewModel.state {
                    return true
                }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    favoriteBusStopsViewModel.dismissError()
                }
            }
        )
    }

    private var favoriteErrorMessage: String {
        if case let .failed(message) = favoriteBusStopsViewModel.state {
            return message
        }
        return "Your favourites could not be updated."
    }
}
