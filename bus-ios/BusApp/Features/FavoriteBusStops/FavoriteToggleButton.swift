import SwiftUI

struct FavoriteToggleButton: View {
    let busStop: BusStop
    let viewModel: FavoriteBusStopsViewModel

    var body: some View {
        let isFavorite = viewModel.isFavorite(busStop)

        Button {
            viewModel.toggle(busStop)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(isFavorite ? .yellow : .secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(
            isFavorite ? "Remove \(busStop.description) from favourites"
                : "Add \(busStop.description) to favourites"
        )
    }
}
