import SwiftUI

@main
struct BusApp: App {
    private let apiClient: BackendAPIClient

    init() {
        apiClient = BackendAPIClient(baseURL: AppConfiguration.backendBaseURL)
    }

    var body: some Scene {
        WindowGroup {
            BusStopSearchView(apiClient: apiClient)
        }
    }
}
