import SwiftUI

struct BusArrivalView: View {
    @Environment(\.openURL) private var openURL

    let busStop: BusStop

    @State private var viewModel: BusArrivalViewModel
    @State private var reminderViewModel: ArrivalReminderViewModel
    private let timeFormatter: ArrivalTimeFormatter
    private let favoriteBusStopsViewModel: FavoriteBusStopsViewModel

    init(
        busStop: BusStop,
        apiClient: any BusArrivalAPIClient,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel,
        reminderScheduler: any ArrivalReminderScheduling = UserNotificationArrivalReminderScheduler(),
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
        _reminderViewModel = State(
            initialValue: ArrivalReminderViewModel(
                stopCode: busStop.stopCode,
                stopName: busStop.description,
                scheduler: reminderScheduler
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
        .task {
            await reminderViewModel.loadPendingReminders()
        }
        .alert("Reminder Unavailable", isPresented: reminderErrorIsPresented) {
            if reminderViewModel.permissionDenied {
                Button("Open Settings") {
                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
            Button("OK", role: .cancel) {
                reminderViewModel.dismissError()
            }
        } message: {
            Text(reminderViewModel.errorMessage ?? "The reminder could not be created.")
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
                        timeFormatter: timeFormatter,
                        reminderViewModel: reminderViewModel
                    )
                }
            }
        }
    }

    private var reminderErrorIsPresented: Binding<Bool> {
        Binding(
            get: { reminderViewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    reminderViewModel.dismissError()
                }
            }
        )
    }
}

private struct BusServiceArrivalRow: View {
    let service: BusServiceArrival
    let timeFormatter: ArrivalTimeFormatter
    let reminderViewModel: ArrivalReminderViewModel

    @State private var showingReminderOptions = false

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

                    reminderButton
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
        .confirmationDialog(
            "Bus \(service.serviceNo) Reminder",
            isPresented: $showingReminderOptions,
            titleVisibility: .visible
        ) {
            reminderActions
        } message: {
            Text("This reminder applies only to the next displayed bus and will not repeat.")
        }
    }

    @ViewBuilder
    private var reminderButton: some View {
        if reminderViewModel.schedulingServiceNo == service.serviceNo {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Scheduling reminder")
        } else if reminderViewModel.activeReminder(for: service.serviceNo) != nil
                    || !reminderViewModel.availableLeadTimes(for: service).isEmpty {
            Button {
                showingReminderOptions = true
            } label: {
                Image(
                    systemName: reminderViewModel.activeReminder(for: service.serviceNo) == nil
                        ? "bell.badge"
                        : "bell.fill"
                )
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                reminderViewModel.activeReminder(for: service.serviceNo) == nil
                    ? "Set one-off reminder for bus \(service.serviceNo)"
                    : "Manage reminder for bus \(service.serviceNo)"
            )
        }
    }

    @ViewBuilder
    private var reminderActions: some View {
        if let reminder = reminderViewModel.activeReminder(for: service.serviceNo) {
            Button("Cancel \(reminder.leadTimeMinutes)-Minute Reminder", role: .destructive) {
                reminderViewModel.cancelReminder(for: service.serviceNo)
            }
        } else {
            ForEach(reminderViewModel.availableLeadTimes(for: service), id: \.self) { minutes in
                Button("Notify \(minutes) Minute\(minutes == 1 ? "" : "s") Before") {
                    Task {
                        await reminderViewModel.scheduleReminder(
                            for: service,
                            leadTimeMinutes: minutes
                        )
                    }
                }
            }
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
