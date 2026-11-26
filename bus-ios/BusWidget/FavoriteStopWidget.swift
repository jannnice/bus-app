import AppIntents
import SwiftUI
import WidgetKit

@main
struct FavoriteStopWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: BusWidgetData.widgetKind,
            intent: FavoriteStopWidgetConfiguration.self,
            provider: FavoriteStopProvider()
        ) { entry in
            FavoriteStopWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Favourite Stop Arrivals")
        .description("Check the next buses at one of your favourite stops.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FavoriteStopEntry: TimelineEntry {
    enum Status {
        case arrivals, noPredictions, expired, waiting, noFavorites, selectStop, removed, storageUnavailable
    }

    let date: Date
    let stop: BusStop?
    let status: Status
    var predictions: [BusStopArrivalPreview] = []
    var fetchedAt: Date?
    var failure: BusWidgetRefreshFailure?
    var isSample = false
}

struct FavoriteStopProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> FavoriteStopEntry { sample() }

    func snapshot(for configuration: FavoriteStopWidgetConfiguration, in context: Context) async -> FavoriteStopEntry {
        context.isPreview ? sample() : entry(for: configuration, at: .now)
    }

    func timeline(for configuration: FavoriteStopWidgetConfiguration, in context: Context) async -> Timeline<FavoriteStopEntry> {
        let initial = entry(for: configuration, at: .now)
        guard let stop = initial.stop else {
            return Timeline(entries: [initial], policy: .never)
        }

        await WidgetArrivalLoader.shared.refresh(stopCode: stop.stopCode, manual: false)
        let now = Date.now
        let current = entry(for: configuration, at: now)
        guard current.stop != nil else { return Timeline(entries: [current], policy: .never) }

        let attempt = BusWidgetData.open()?.attempt(for: stop.stopCode)
        let interval = attempt?.failure?.retryDelay ?? WidgetArrivalLoader.automaticInterval
        let earliestReload = (attempt?.startedAt ?? now).addingTimeInterval(interval)
        let nextReload = max(now.addingTimeInterval(5 * 60), earliestReload)
        var entries = [current]
        if let fetchedAt = current.fetchedAt, current.status == .arrivals || current.status == .noPredictions {
            let expires = fetchedAt.addingTimeInterval(BusWidgetSnapshot.maximumAge)
            entries.append(FavoriteStopEntry(
                date: expires, stop: stop, status: .expired,
                fetchedAt: fetchedAt, failure: current.failure
            ))
        }
        return Timeline(entries: entries, policy: .after(nextReload))
    }

    private func entry(for configuration: FavoriteStopWidgetConfiguration, at now: Date) -> FavoriteStopEntry {
        guard let data = BusWidgetData.open(), let favorites = try? data.favorites() else {
            return FavoriteStopEntry(date: now, stop: nil, status: .storageUnavailable)
        }
        guard !favorites.isEmpty else {
            return FavoriteStopEntry(date: now, stop: nil, status: .noFavorites)
        }
        guard let code = configuration.stop?.id else {
            return FavoriteStopEntry(date: now, stop: nil, status: .selectStop)
        }
        guard let stop = favorites.first(where: { $0.stopCode == code }) else {
            return FavoriteStopEntry(date: now, stop: nil, status: .removed)
        }

        let snapshot = data.snapshot(for: code)
        let attempt = data.attempt(for: code)
        let failure = attempt.flatMap { attempt in
            attempt.startedAt >= (snapshot?.fetchedAt ?? .distantPast) ? attempt.failure : nil
        }
        guard let snapshot else {
            return FavoriteStopEntry(date: now, stop: stop, status: .waiting, failure: failure)
        }
        let status: FavoriteStopEntry.Status = if snapshot.isExpired(at: now) {
            .expired
        } else if snapshot.arrivals.isEmpty {
            .noPredictions
        } else {
            .arrivals
        }
        return FavoriteStopEntry(
            date: now, stop: stop, status: status, predictions: snapshot.predictions(at: now),
            fetchedAt: snapshot.fetchedAt, failure: failure
        )
    }

    private func sample() -> FavoriteStopEntry {
        let now = Date.now
        let stop = BusStop(
            stopCode: "01012", roadName: "Victoria St", description: "Hotel Grand Pacific",
            latitude: 1.29685, longitude: 103.853
        )
        let predictions = zip(["2", "12", "33", "130"], [3, 5, 7, 11]).map { service, minutes in
            BusStopArrivalPreview(serviceNo: service, estimatedArrival: now.addingTimeInterval(Double(minutes) * 60))
        }
        return FavoriteStopEntry(date: now, stop: stop, status: .arrivals,
                                 predictions: predictions, fetchedAt: now, isSample: true)
    }
}
