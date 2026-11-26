import SwiftUI
import WidgetKit

@main
struct BusApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self)
    private var notificationDelegate

    private let apiClient: BackendAPIClient
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init() {
        let widgetData = BusWidgetData.open()
        if let widgetData {
            UserDefaultsFavoriteBusStopStorage.migrateFavorites(from: .standard, to: widgetData.defaults)
        }
        apiClient = BackendAPIClient(
            baseURL: AppConfiguration.backendBaseURL,
            apiToken: AppConfiguration.backendAPIToken
        ) { response, requestedAt in
            guard let widgetData = BusWidgetData.open(),
                  let favorites = try? widgetData.favorites(),
                  favorites.contains(where: { $0.stopCode == response.stopCode }) else { return }

            widgetData.save(
                BusWidgetSnapshot(response: response, fetchedAt: requestedAt),
                for: response.stopCode,
                fromApp: true
            )
        }
        favoriteBusStopsViewModel = FavoriteBusStopsViewModel(
            storage: UserDefaultsFavoriteBusStopStorage(userDefaults: widgetData?.defaults ?? .standard) {
                WidgetCenter.shared.reloadTimelines(ofKind: BusWidgetData.widgetKind)
            }
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
