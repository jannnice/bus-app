import SwiftUI

struct BusStopArrivalPreviewView: View {
    let stopCode: String
    let store: BusStopArrivalPreviewStore
    let timeFormatter: ArrivalTimeFormatter

    init(
        stopCode: String,
        store: BusStopArrivalPreviewStore,
        timeFormatter: ArrivalTimeFormatter = ArrivalTimeFormatter()
    ) {
        self.stopCode = stopCode
        self.store = store
        self.timeFormatter = timeFormatter
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            content(now: context.date)
        }
        .task(id: stopCode) {
            await store.runAutoRefresh(stopCode: stopCode)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch store.state(for: stopCode) {
        case .idle, .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading arrivals...")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

        case let .loaded(previews):
            HStack(spacing: 6) {
                ForEach(previews) { preview in
                    VStack(spacing: 2) {
                        Text(preview.serviceNo)
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.primary)

                        Text(
                            timeFormatter.string(
                                for: preview.estimatedArrival,
                                relativeTo: now
                            )
                        )
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityElement(children: .combine)
                }
            }

        case .empty:
            Label("No live arrivals", systemImage: "bus")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .failed:
            Label("Arrivals unavailable", systemImage: "wifi.exclamationmark")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
