import SwiftUI

struct BusStopSearchView: View {
    @State private var viewModel: BusStopSearchViewModel

    init(apiClient: any BusStopAPIClient) {
        _viewModel = State(initialValue: BusStopSearchViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Searching bus stops...")
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Couldn’t Search", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task { await viewModel.search() }
                        }
                    }
                } else if viewModel.hasSearched && viewModel.busStops.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else if viewModel.busStops.isEmpty {
                    ContentUnavailableView {
                        Label("Find a Bus Stop", systemImage: "bus")
                    } description: {
                        Text("Search by stop code, landmark, or road name.")
                    }
                } else {
                    List(viewModel.busStops) { busStop in
                        BusStopRow(busStop: busStop)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Bus Stops")
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Code, landmark, or road"
            )
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .onChange(of: viewModel.query) { _, newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { await viewModel.search() }
                }
            }
        }
    }
}

#Preview {
    BusStopSearchView(apiClient: PreviewBusStopAPIClient())
}

private struct PreviewBusStopAPIClient: BusStopAPIClient {
    func searchBusStops(query: String, limit: Int) async throws -> [BusStop] {
        [
            BusStop(
                stopCode: "01012",
                roadName: "Victoria St",
                description: "Hotel Grand Pacific",
                latitude: 1.29685,
                longitude: 103.853
            )
        ]
    }
}
