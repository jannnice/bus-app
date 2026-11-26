import SwiftUI

struct FavoriteBusStopsView: View {
    let apiClient: any BusArrivalAPIClient
    let viewModel: FavoriteBusStopsViewModel
    let arrivalPreviewStore: BusStopArrivalPreviewStore
    @Binding private var path: [BusStop]

    init(
        apiClient: any BusArrivalAPIClient,
        viewModel: FavoriteBusStopsViewModel,
        arrivalPreviewStore: BusStopArrivalPreviewStore? = nil,
        path: Binding<[BusStop]>
    ) {
        self.apiClient = apiClient
        self.viewModel = viewModel
        self.arrivalPreviewStore = arrivalPreviewStore
            ?? BusStopArrivalPreviewStore(apiClient: apiClient)
        _path = path
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.busStops.isEmpty {
                    ContentUnavailableView {
                        Label("No Favourites", systemImage: "star")
                    } description: {
                        Text("Tap a star on any bus stop to keep it here.")
                    }
                } else {
                    List {
                        ForEach(viewModel.busStops) { busStop in
                            NavigationLink(value: busStop) {
                                VStack(alignment: .leading, spacing: 10) {
                                    BusStopRow(busStop: busStop)

                                    BusStopArrivalPreviewView(
                                        stopCode: busStop.stopCode,
                                        store: arrivalPreviewStore
                                    )
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: viewModel.remove)
                        .onMove(perform: viewModel.move)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(for: BusStop.self) { stop in
                BusArrivalView(busStop: stop, apiClient: apiClient, favoriteBusStopsViewModel: viewModel)
            }
            .navigationTitle("Favourites")
            .toolbar {
                if !viewModel.busStops.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

#Preview {
    FavoriteBusStopsView(
        apiClient: PreviewFavoriteArrivalAPIClient(),
        viewModel: .preview(
            busStops: [
                BusStop(
                    stopCode: "01012",
                    roadName: "Victoria St",
                    description: "Hotel Grand Pacific",
                    latitude: 1.29685,
                    longitude: 103.853
                )
            ]
        ),
        path: .constant([])
    )
}

private struct PreviewFavoriteArrivalAPIClient: BusArrivalAPIClient {
    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        BusArrivalResponse(stopCode: stopCode, services: [])
    }
}
