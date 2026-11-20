import MapKit
import SwiftUI

struct NearbyBusStopsMap: View {
    let busStops: [NearbyBusStop]
    let region: NearbyMapRegion
    let selectedBusStop: NearbyBusStop?
    let arrivalAPIClient: any BusArrivalAPIClient
    let favoriteBusStopsViewModel: FavoriteBusStopsViewModel
    let distanceFormatter: DistanceFormatter
    let onSelect: (String?) -> Void

    @State private var cameraPosition: MapCameraPosition

    init(
        busStops: [NearbyBusStop],
        region: NearbyMapRegion,
        selectedBusStop: NearbyBusStop?,
        arrivalAPIClient: any BusArrivalAPIClient,
        favoriteBusStopsViewModel: FavoriteBusStopsViewModel,
        distanceFormatter: DistanceFormatter,
        onSelect: @escaping (String?) -> Void
    ) {
        self.busStops = busStops
        self.region = region
        self.selectedBusStop = selectedBusStop
        self.arrivalAPIClient = arrivalAPIClient
        self.favoriteBusStopsViewModel = favoriteBusStopsViewModel
        self.distanceFormatter = distanceFormatter
        self.onSelect = onSelect
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
                cameraPosition = .region(region.coordinateRegion)
            } label: {
                Image(systemName: "scope")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding()
            .accessibilityLabel("Show all nearby stops")
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedBusStop {
                selectedStopCard(for: selectedBusStop)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .onChange(of: region) { _, updatedRegion in
            cameraPosition = .region(updatedRegion.coordinateRegion)
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

    private func selectedStopCard(for nearbyBusStop: NearbyBusStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            NavigationLink {
                BusArrivalView(
                    busStop: nearbyBusStop.busStop,
                    apiClient: arrivalAPIClient,
                    favoriteBusStopsViewModel: favoriteBusStopsViewModel
                )
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nearbyBusStop.description)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(nearbyBusStop.roadName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(
                        "Stop \(nearbyBusStop.stopCode) · "
                            + distanceFormatter.string(for: nearbyBusStop.distanceMeters)
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            FavoriteToggleButton(
                busStop: nearbyBusStop.busStop,
                viewModel: favoriteBusStopsViewModel
            )

            Button {
                onSelect(nil)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close stop details")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 3, y: 1)
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
