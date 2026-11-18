import SwiftUI

struct BusArrivalView: View {
    let busStop: BusStop

    @State private var viewModel: BusArrivalViewModel
    private let timeFormatter: ArrivalTimeFormatter
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init(
        busStop: BusStop,
        apiClient: any BusArrivalAPIClient,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel,
        timeFormatter: ArrivalTimeFormatter = ArrivalTimeFormatter()
    ) {
        self.busStop = busStop
        self.timeFormatter = timeFormatter
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
        _viewModel = State(
            initialValue: BusArrivalViewModel(
                stopCode: busStop.stopCode,
                apiClient: apiClient
            )
        )
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(busStop.description)
                        .font(.title2.bold())

                    Text(busStop.roadName)
                        .foregroundStyle(.secondary)

                    Label("Stop \(busStop.stopCode)", systemImage: "mappin.and.ellipse")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }

            arrivalsContent
        }
        .navigationTitle("Live Arrivals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteToggleButton(
                    busStop: busStop,
                    viewModel: favoriteBusStopsViewModel
                )
            }
        }
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.runAutoRefresh()
        }
    }

    @ViewBuilder
    private var arrivalsContent: some View {
        switch viewModel.state {
        case .loading:
            Section {
                HStack {
                    Spacer()
                    ProgressView("Loading arrivals...")
                    Spacer()
                }
                .padding(.vertical, 32)
            }

        case .empty:
            Section {
                ContentUnavailableView {
                    Label("No Services", systemImage: "bus")
                } description: {
                    Text("No live bus services are available for this stop right now.")
                }
            }

        case let .failed(message):
            Section {
                ContentUnavailableView {
                    Label("Couldn’t Load Arrivals", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                }
            }

        case .loaded:
            Section("Services") {
                ForEach(viewModel.services) { service in
                    BusServiceArrivalRow(
                        service: service,
                        timeFormatter: timeFormatter
                    )
                }
            }
        }
    }
}

private struct BusServiceArrivalRow: View {
    let service: BusServiceArrival
    let timeFormatter: ArrivalTimeFormatter

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(service.serviceNo)
                        .font(.title2.bold().monospacedDigit())

                    Spacer()

                    Text(service.operator)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        predictionColumn(
                            prediction: service.arrivals[safe: index],
                            now: context.date
                        )

                        if index < 2 {
                            Divider()
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func predictionColumn(
        prediction: BusArrivalPrediction?,
        now: Date
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(timeFormatter.string(for: prediction?.estimatedArrival, relativeTo: now))
                .font(.headline.monospacedDigit())
                .foregroundStyle(prediction == nil ? .secondary : .primary)

            if let prediction {
                Label(prediction.load.displayName, systemImage: "person.2")
                Label(
                    prediction.wheelchairAccessible ? "Wheelchair" : "No wheelchair",
                    systemImage: "figure.roll"
                )
                Label(prediction.type.displayName, systemImage: "bus.doubledecker")
            } else {
                Text("No prediction")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        BusArrivalView(
            busStop: BusStop(
                stopCode: "01012",
                roadName: "Victoria St",
                description: "Hotel Grand Pacific",
                latitude: 1.29685,
                longitude: 103.853
            ),
            apiClient: PreviewBusArrivalAPIClient(),
            favoriteBusStopsViewModel: .preview()
        )
    }
}

private struct PreviewBusArrivalAPIClient: BusArrivalAPIClient {
    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        BusArrivalResponse(
            stopCode: stopCode,
            services: [
                BusServiceArrival(
                    serviceNo: "15",
                    operator: "GAS",
                    arrivals: [
                        BusArrivalPrediction(
                            originCode: "77009",
                            destinationCode: "77009",
                            estimatedArrival: Date().addingTimeInterval(180),
                            monitored: true,
                            latitude: 1.315,
                            longitude: 103.905,
                            visitNumber: 1,
                            load: .seatsAvailable,
                            wheelchairAccessible: true,
                            type: .singleDeck
                        )
                    ]
                )
            ]
        )
    }
}
