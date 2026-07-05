//
//  SearchSheet.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

import SwiftUI
import MapKit

struct SearchSheet: View {
    let center: CLLocationCoordinate2D
    @Binding var bookmarks: Set<String>
    let onSelect: (PlaceResult) -> Void

    @State private var query       = ""
    @State private var results: [PlaceResult] = []
    @State private var isSearching = false
    @State private var completer   = SearchCompleterManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            // Search bar + anchor dismiss
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search a location", text: $query)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }
                    if !query.isEmpty {
                        Button { query = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "mic.fill").foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6), in: Capsule())

                // Anchor button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Theme.primary, in: Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            if isSearching {
                ProgressView().padding()
            } else {
                List(results) { place in
                    SearchResultRow(
                        place: place,
                        isBookmarked: bookmarks.contains(place.name),
                        onBookmark: {
                            if bookmarks.contains(place.name) { bookmarks.remove(place.name) }
                            else { bookmarks.insert(place.name) }
                        }
                    )
                    .listRowSeparator(.visible)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(place); dismiss() }
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: query) { _, newVal in
            completer.update(query: newVal, around: center)
        }
    }

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }
        results = (try? await PlaceSearchService.search(query: query, around: center)) ?? []
    }
}
