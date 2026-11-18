import SwiftUI

struct NearbyBusStopRow: View {
    let busStop: NearbyBusStop
    let distanceFormatter: DistanceFormatter

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "location.fill")
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(busStop.description)
                    .font(.headline)

                Text(busStop.roadName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Stop \(busStop.stopCode)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(distanceFormatter.string(for: busStop.distanceMeters))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(busStop.description), \(busStop.roadName), stop \(busStop.stopCode), "
                + "\(distanceFormatter.string(for: busStop.distanceMeters)) away"
        )
    }
}
