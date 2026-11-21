import SwiftUI

struct BusAppRootView: View {
    let apiClient: BackendAPIClient
    let favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    @State private var arrivalPreviewStore: BusStopArrivalPreviewStore

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
        TabView {
            NearbyBusStopsView(
                apiClient: apiClient,
                locationProvider: CoreLocationProvider(),
                favoriteBusStopsViewModel: favoriteBusStopsViewModel,
                arrivalPreviewStore: arrivalPreviewStore
            )
            .tabItem {
                Label("Nearby", systemImage: "location")
            }

            BusStopSearchView(
                apiClient: apiClient,
                favoriteBusStopsViewModel: favoriteBusStopsViewModel
            )
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavoriteBusStopsView(
                apiClient: apiClient,
                viewModel: favoriteBusStopsViewModel,
                arrivalPreviewStore: arrivalPreviewStore
            )
            .tabItem {
                Label("Favourites", systemImage: "star")
            }
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
