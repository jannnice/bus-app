import SwiftUI

struct BusStopSearchView: View {
    @State private var viewModel: BusStopSearchViewModel
    private let arrivalAPIClient: any BusArrivalAPIClient
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init(
        apiClient: any BusStopAPIClient & BusArrivalAPIClient,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    ) {
        _viewModel = State(initialValue: BusStopSearchViewModel(apiClient: apiClient))
        arrivalAPIClient = apiClient
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
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
                        HStack(spacing: 8) {
                            NavigationLink {
                                BusArrivalView(
                                    busStop: busStop,
                                    apiClient: arrivalAPIClient,
                                    favoriteBusStopsViewModel: favoriteBusStopsViewModel
                                )
                            } label: {
                                BusStopRow(busStop: busStop)
                            }

                            FavoriteToggleButton(
                                busStop: busStop,
                                viewModel: favoriteBusStopsViewModel
                            )
                        }
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
    BusStopSearchView(
        apiClient: PreviewBusStopAPIClient(),
        favoriteBusStopsViewModel: .preview()
    )
}

private struct PreviewBusStopAPIClient: BusStopAPIClient, BusArrivalAPIClient {
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

    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        BusArrivalResponse(stopCode: stopCode, services: [])
    }
}
