//
//  SearchCompleterManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

//  Autocomplete saran saat user mengetik di SearchSheet.
//  Adapted dari SearchCompleter teman tim ke @Observable pattern.
//

import MapKit

/// Mengelola MKLocalSearchCompleter — memberikan saran autocomplete
/// saat user mengetik query di SearchSheet.
@Observable
final class SearchCompleterManager: NSObject {

    var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    /// Update saran berdasarkan query dan posisi pusat peta.
    func update(query: String, around center: CLLocationCoordinate2D) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
        completer.queryFragment = trimmed
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension SearchCompleterManager: MKLocalSearchCompleterDelegate {

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in self.suggestions = results }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        Task { @MainActor in self.suggestions = [] }
    }
}
