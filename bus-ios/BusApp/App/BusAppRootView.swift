import SwiftUI

struct BusAppRootView: View {
    let apiClient: BackendAPIClient

    var body: some View {
        TabView {
            BusStopSearchView(apiClient: apiClient)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            NearbyBusStopsView(
                apiClient: apiClient,
                locationProvider: CoreLocationProvider()
            )
            .tabItem {
                Label("Nearby", systemImage: "location")
            }
        }
    }
}
