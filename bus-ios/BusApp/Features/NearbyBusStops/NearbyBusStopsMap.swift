import MapKit
import SwiftUI

struct NearbyBusStopsMap: View {
    let busStops: [NearbyBusStop]
    let region: NearbyMapRegion
    let homeRegion: NearbyMapRegion
    let selectedBusStop: NearbyBusStop?
    let arrivalAPIClient: any BusArrivalAPIClient
    let favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    let arrivalPreviewStore: BusStopArrivalPreviewStore
    let distanceFormatter: DistanceFormatter
    let canSearchMapArea: Bool
    let isSearchingMapArea: Bool
    let onSelect: (String?) -> Void
    let onVisibleCenterChange: (UserLocation) -> Void
    let onRecenterToUserLocation: () async -> Void
    let onSearchMapArea: () async -> Void

    @State private var cameraPosition: MapCameraPosition

    init(
        busStops: [NearbyBusStop],
        region: NearbyMapRegion,
        homeRegion: NearbyMapRegion,
        selectedBusStop: NearbyBusStop?,
        arrivalAPIClient: any BusArrivalAPIClient,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel,
        arrivalPreviewStore: BusStopArrivalPreviewStore,
        distanceFormatter: DistanceFormatter,
        canSearchMapArea: Bool,
        isSearchingMapArea: Bool,
        onSelect: @escaping (String?) -> Void,
        onVisibleCenterChange: @escaping (UserLocation) -> Void,
        onRecenterToUserLocation: @escaping () async -> Void,
        onSearchMapArea: @escaping () async -> Void
    ) {
        self.busStops = busStops
        self.region = region
        self.homeRegion = homeRegion
        self.selectedBusStop = selectedBusStop
        self.arrivalAPIClient = arrivalAPIClient
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
        self.arrivalPreviewStore = arrivalPreviewStore
        self.distanceFormatter = distanceFormatter
        self.canSearchMapArea = canSearchMapArea
        self.isSearchingMapArea = isSearchingMapArea
        self.onSelect = onSelect
        self.onVisibleCenterChange = onVisibleCenterChange
        self.onRecenterToUserLocation = onRecenterToUserLocation
        self.onSearchMapArea = onSearchMapArea
        _cameraPosition = State(initialValue: .region(region.coordinateRegion))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(annotations) { annotation in
                Annotation(
                    annotation.title,
                    coordinate: annotation.coordinate,
                    anchor: .bottom
                ) {
                    mapMarker(for: annotation)
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.35)) {
                    cameraPosition = .region(homeRegion.coordinateRegion)
                }
                Task {
                    await onRecenterToUserLocation()
                }
            } label: {
                Image(systemName: "scope")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding()
            .disabled(isSearchingMapArea)
            .accessibilityLabel("Go to my location")
            .accessibilityHint("Centers the map and reloads nearby bus stops")
        }
        .overlay(alignment: .top) {
            searchMapAreaControl
                .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) {
            if !busStops.isEmpty {
                NearbyBusStopsPreviewPanel(
                    busStops: busStops,
                    selectedStopCode: selectedBusStop?.stopCode,
                    arrivalAPIClient: arrivalAPIClient,
                    favoriteBusStopsViewModel: favoriteBusStopsViewModel,
                    arrivalPreviewStore: arrivalPreviewStore,
                    distanceFormatter: distanceFormatter
                )
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            guard cameraPosition.positionedByUser else {
                return
            }

            onVisibleCenterChange(
                UserLocation(
                    latitude: context.region.center.latitude,
                    longitude: context.region.center.longitude
                )
            )
        }
    }

    @ViewBuilder
    private var searchMapAreaControl: some View {
        if isSearchingMapArea {
            HStack(spacing: 8) {
                ProgressView()
                Text("Searching this area...")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
        } else if canSearchMapArea {
            Button("Search This Area") {
                Task { await onSearchMapArea() }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
    }

    private var annotations: [NearbyMapAnnotation] {
        busStops.map { busStop in
            NearbyMapAnnotation(
                busStop: busStop,
                isFavorite: favoriteBusStopsViewModel.isFavorite(busStop.busStop)
            )
        }
    }

    private func mapMarker(for annotation: NearbyMapAnnotation) -> some View {
        let isSelected = selectedBusStop?.stopCode == annotation.stopCode

        return Button {
            onSelect(annotation.stopCode)
        } label: {
            Image(systemName: annotation.isFavorite ? "star.fill" : "bus.fill")
                .font(.system(size: isSelected ? 18 : 15, weight: .semibold))
                .foregroundStyle(annotation.isFavorite ? Color.yellow : Color.white)
                .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)
                .background(isSelected ? Color.indigo : Color.accentColor, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
                .shadow(radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(annotation.title), \(distanceFormatter.string(for: annotation.distanceMeters)) away"
                + (annotation.isFavorite ? ", favourite" : "")
        )
        .accessibilityHint("Shows details for this bus stop")
    }

}

private extension NearbyMapAnnotation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension NearbyMapRegion {
    var coordinateRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }
}
