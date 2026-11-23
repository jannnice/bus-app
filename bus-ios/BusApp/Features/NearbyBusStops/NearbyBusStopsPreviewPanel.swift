import SwiftUI

struct NearbyBusStopsPreviewPanel: View {
    let busStops: [NearbyBusStop]
    let selectedStopCode: String?
    let arrivalAPIClient: any BusArrivalAPIClient
    let favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    let arrivalPreviewStore: BusStopArrivalPreviewStore
    let distanceFormatter: DistanceFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nearby Stops")
                    .font(.headline)

                Spacer()

                Text("\(busStops.count) stops")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(orderedBusStops) { nearbyBusStop in
                            stopCard(for: nearbyBusStop)
                                .id(nearbyBusStop.stopCode)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal)
                }
                .frame(height: 132)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: selectedStopCode) { _, stopCode in
                    guard let stopCode else {
                        return
                    }
                    withAnimation {
                        proxy.scrollTo(stopCode, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .fixedSize(horizontal: false, vertical: true)
        .background(.ultraThinMaterial)
    }

    private var orderedBusStops: [NearbyBusStop] {
        NearbyBusStopCarouselOrdering.favoritesFirst(
            busStops,
            favoriteStopCodes: Set(
                favoriteBusStopsViewModel.busStops.map(\.stopCode)
            )
        )
    }

    private func stopCard(for nearbyBusStop: NearbyBusStop) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                NavigationLink {
                    BusArrivalView(
                        busStop: nearbyBusStop.busStop,
                        apiClient: arrivalAPIClient,
                        favoriteBusStopsViewModel: favoriteBusStopsViewModel
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(nearbyBusStop.description)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(nearbyBusStop.roadName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(
                            "Stop \(nearbyBusStop.stopCode) · "
                                + distanceFormatter.string(for: nearbyBusStop.distanceMeters)
                        )
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                FavoriteToggleButton(
                    busStop: nearbyBusStop.busStop,
                    viewModel: favoriteBusStopsViewModel
                )
            }

            NavigationLink {
                BusArrivalView(
                    busStop: nearbyBusStop.busStop,
                    apiClient: arrivalAPIClient,
                    favoriteBusStopsViewModel: favoriteBusStopsViewModel
                )
            } label: {
                BusStopArrivalPreviewView(
                    stopCode: nearbyBusStop.stopCode,
                    store: arrivalPreviewStore
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 300, height: 132, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    selectedStopCode == nearbyBusStop.stopCode
                        ? Color.accentColor
                        : Color.clear,
                    lineWidth: 2
                )
        }
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }
}
