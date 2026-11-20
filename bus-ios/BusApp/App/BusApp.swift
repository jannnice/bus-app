import SwiftUI

@main
struct BusApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self)
    private var notificationDelegate

    private let apiClient: BackendAPIClient
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init() {
        apiClient = BackendAPIClient(
            baseURL: AppConfiguration.backendBaseURL,
            apiToken: AppConfiguration.backendAPIToken
        )
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
