//
//  SearchViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import MapKit
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [PlaceResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var completer = SearchCompleter()
    
    func updateQuery(around center: CLLocationCoordinate2D) {
        results = []
        completer.update(query: query, around: center)
    }
    
    func runSearch(completion: MKLocalSearchCompletion, center: CLLocationCoordinate2D) {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let found = try await PlaceSearchService.search(completion: completion, around: center)
                results = found
                if found.isEmpty {
                    errorMessage = String(format: NSLocalizedString("No results for \"%@\".", comment: ""), completion.title)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func runSearch(around center: CLLocationCoordinate2D) {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let found = try await PlaceSearchService.search(query: query, around: center)
                results = found
                if found.isEmpty {
                    errorMessage = String(format: NSLocalizedString("No results for \"%@\".", comment: ""), query)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleBookmark(for place: PlaceResult, in bookmarks: inout Set<String>) {
        if bookmarks.contains(place.name) {
            bookmarks.remove(place.name)
        } else {
            bookmarks.insert(place.name)
        }
    }
}
