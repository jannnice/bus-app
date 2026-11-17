import Foundation
import Observation

@MainActor
@Observable
final class BusStopSearchViewModel {
    var query = ""
    private(set) var busStops: [BusStop] = []
    private(set) var isLoading = false
    private(set) var hasSearched = false
    private(set) var errorMessage: String?

    private let apiClient: any BusStopAPIClient
    private let resultLimit: Int

    init(apiClient: any BusStopAPIClient, resultLimit: Int = 20) {
        self.apiClient = apiClient
        self.resultLimit = resultLimit
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            busStops = []
            errorMessage = nil
            hasSearched = false
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            hasSearched = true
        }

        do {
            busStops = try await apiClient.searchBusStops(
                query: trimmedQuery,
                limit: resultLimit
            )
        } catch is CancellationError {
            return
        } catch {
            busStops = []
            errorMessage = error.localizedDescription
        }
    }
}
