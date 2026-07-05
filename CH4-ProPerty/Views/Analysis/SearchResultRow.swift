//
//  SearchResultRow.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

import SwiftUI

struct SearchResultRow: View {
    let place: PlaceResult
    let isBookmarked: Bool
    let onBookmark: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // Pin merah + jarak di bawahnya
            VStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.pin)
                if let dist = place.distanceLabel {
                    Text(dist)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44)

            // Nama + subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(place.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if !place.subtitle.isEmpty {
                    Text(place.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Bookmark icon
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    List {
        SearchResultRow(
            place: PlaceResult(
                name: "Canggu",
                subtitle: "Kabupaten Badung, Bali, Indonesia",
                latitude: -8.647,
                longitude: 115.132,
                distanceKm: 10.3
            ),
            isBookmarked: false,
            onBookmark: {}
        )
        SearchResultRow(
            place: PlaceResult(
                name: "Kuta",
                subtitle: "Kabupaten Badung, Bali, Indonesia",
                latitude: -8.718,
                longitude: 115.168,
                distanceKm: 1.7
            ),
            isBookmarked: true,
            onBookmark: {}
        )
    }
    .listStyle(.plain)
}
