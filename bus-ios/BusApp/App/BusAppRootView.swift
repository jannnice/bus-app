import SwiftUI

struct BusAppRootView: View {
    let apiClient: BackendAPIClient
    let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    var body: some View {
        TabView {
            BusStopSearchView(
                apiClient: apiClient,
                favoriteBusStopsViewModel: favoriteBusStopsViewModel
            )
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            NearbyBusStopsView(
                apiClient: apiClient,
                locationProvider: CoreLocationProvider(),
                favoriteBusStopsViewModel: favoriteBusStopsViewModel
            )
            .tabItem {
                Label("Nearby", systemImage: "location")
            }

            FavoriteBusStopsView(
                apiClient: apiClient,
                viewModel: favoriteBusStopsViewModel
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
