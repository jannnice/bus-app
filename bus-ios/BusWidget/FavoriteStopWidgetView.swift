import SwiftUI
import WidgetKit

struct FavoriteStopWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FavoriteStopEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Spacer(minLength: 0)
            Group {
                if entry.status == .arrivals {
                    arrivals
                } else {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .invalidatableContent()
            Spacer(minLength: 0)
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(link)
    }

    private var link: URL? {
        if entry.isSample { return nil }
        return entry.stop.flatMap { BusWidgetLink.arrivals($0.stopCode).url } ?? BusWidgetLink.favorites.url
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.stop?.description ?? "Bus Arrivals")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(family == .systemSmall ? 2 : 1)
                if let code = entry.stop?.stopCode {
                    Text("Stop \(code)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let code = entry.stop?.stopCode, !entry.isSample {
                Button(intent: RefreshWidgetArrivalsIntent(stopCode: code)) {
                    Image(systemName: "arrow.clockwise")
                        .font(.footnote.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .background(.fill.tertiary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh arrivals")
            }
        }
    }

    private var arrivals: some View {
        HStack(spacing: 4) {
            ForEach(entry.predictions.prefix(family == .systemSmall ? 2 : 4)) { prediction in
                VStack(alignment: .leading, spacing: 2) {
                    Text(prediction.serviceNo)
                        .font(.headline.monospacedDigit())
                    Text(prediction.estimatedArrival, style: .time)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Bus \(prediction.serviceNo), estimated at \(prediction.estimatedArrival, style: .time)"))
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let fetchedAt = entry.fetchedAt {
            VStack(alignment: .leading, spacing: 1) {
                if let failure = entry.failure, entry.status == .arrivals {
                    Text(message(for: failure))
                        .lineLimit(1)
                }
                if entry.status == .arrivals, entry.failure == nil {
                    Text("Est. · Updated \(fetchedAt, style: .time)")
                } else {
                    Text("Updated \(fetchedAt, style: .time)")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }

    private var statusMessage: LocalizedStringKey {
        if let failure = entry.failure { return message(for: failure) }
        switch entry.status {
        case .arrivals: return ""
        case .noPredictions: return "No arrivals reported"
        case .expired: return "Estimates expired. Tap refresh."
        case .waiting: return "Waiting for arrivals"
        case .noFavorites: return "Save a favourite stop in Bus App."
        case .selectStop: return "Edit this widget to choose a stop."
        case .removed: return "Choose another favourite stop."
        case .storageUnavailable: return "Favourites unavailable"
        }
    }

    private func message(for failure: BusWidgetRefreshFailure) -> LocalizedStringKey {
        switch failure {
        case .offline: "Offline"
        case .unavailable: "Refresh failed"
        case .authentication, .configuration: "Backend setup needed"
        case .rateLimited: "Try again shortly"
        }
    }
}
