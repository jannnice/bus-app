import SwiftUI

@main
struct BusApp: App {
    private let apiClient: BackendAPIClient
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init() {
        apiClient = BackendAPIClient(baseURL: AppConfiguration.backendBaseURL)
        favoriteBusStopsViewModel = FavoriteBusStopsViewModel(
            storage: UserDefaultsFavoriteBusStopStorage()
        )
    }

    var body: some Scene {
        WindowGroup {
            BusAppRootView(
                apiClient: apiClient,
                favoriteBusStopsViewModel: favoriteBusStopsViewModel
            )
        }
    }
}
