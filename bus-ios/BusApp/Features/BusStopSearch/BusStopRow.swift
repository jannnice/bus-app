import SwiftUI

struct BusStopRow: View {
    let busStop: BusStop

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bus.fill")
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(busStop.description)
                    .font(.headline)

                Text(busStop.roadName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(busStop.stopCode)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(busStop.description), \(busStop.roadName), stop \(busStop.stopCode)"
        )
    }
}
