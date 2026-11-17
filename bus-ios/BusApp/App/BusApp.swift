import SwiftUI

@main
struct BusApp: App {
    private let apiClient: any BusStopAPIClient

    init() {
        apiClient = BackendAPIClient(baseURL: AppConfiguration.backendBaseURL)
    }

    var body: some Scene {
        WindowGroup {
            BusStopSearchView(apiClient: apiClient)
        }
    }
}
