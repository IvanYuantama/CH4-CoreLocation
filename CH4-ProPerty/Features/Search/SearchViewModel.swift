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
class SearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = ""
    @Published var results: [PlaceResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Bookmark
    @Published var savedPlaces: [PlaceResult] = []
    private let saveKey = "bookmarked_places_v2"
    
    // Engine Autocomplete dari Apple
    private var completer = MKLocalSearchCompleter()
    private var center: CLLocationCoordinate2D?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        loadBookmarks()
        
        completer.delegate = self
        // 🌟 PERBAIKAN 1: Hapus .query agar Apple hanya mengembalikan lokasi fisik nyata
        completer.resultTypes = [.address, .pointOfInterest]
        
        $query
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main) // Beri sedikit nafas ekstra untuk API
            .removeDuplicates()
            .sink { [weak self] newQuery in
                guard let self = self else { return }
                if newQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.results = []
                    self.isLoading = false
                    self.errorMessage = nil
                } else {
                    self.isLoading = true
                    self.completer.queryFragment = newQuery
                }
            }
            .store(in: &cancellables)
    }
    
    func setCenter(_ newCenter: CLLocationCoordinate2D) {
        self.center = newCenter
        self.completer.region = MKCoordinateRegion(
            center: newCenter,
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let topSuggestions = Array(completer.results.prefix(6))
        
        Task { @MainActor in
            guard let center = self.center else { return }
            let currentQuery = self.query
            
            var resultsDict: [Int: PlaceResult] = [:]
            
            await withTaskGroup(of: (Int, PlaceResult?).self) { group in
                for (index, suggestion) in topSuggestions.enumerated() {
                    group.addTask {
                        let found = try? await PlaceSearchService.search(completion: suggestion, around: center)
                        
                        if let place = found?.first {
                            let exactMatchPlace = PlaceResult(
                                name: suggestion.title,
                                subtitle: suggestion.subtitle.isEmpty ? place.subtitle : suggestion.subtitle,
                                latitude: place.latitude,
                                longitude: place.longitude,
                                distanceKm: place.distanceKm
                            )
                            return (index, exactMatchPlace)
                        }
                        return (index, nil)
                    }
                }
                
                for await (index, result) in group {
                    if let result = result {
                        resultsDict[index] = result
                    }
                }
            }
            
            var finalResults: [PlaceResult] = []
            for i in 0..<topSuggestions.count {
                if let res = resultsDict[i] {
                    finalResults.append(res)
                }
            }
            
            if finalResults.isEmpty && !topSuggestions.isEmpty {
                if let fallbackFound = try? await PlaceSearchService.search(query: currentQuery, around: center) {
                    // Ambil 6 teratas dari hasil fallback
                    finalResults = Array(fallbackFound.prefix(6))
                }
            }
            
            self.results = finalResults
            self.isLoading = false
            
            if self.results.isEmpty {
                self.errorMessage = "No results found for \"\(currentQuery)\"."
            } else {
                self.errorMessage = nil
            }
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            // Jika autocomplete gagal, langsung jalankan fallback pencarian normal
            guard let center = self.center else {
                self.isLoading = false
                return
            }
            
            if let fallbackFound = try? await PlaceSearchService.search(query: self.query, around: center) {
                self.results = Array(fallbackFound.prefix(6))
                self.errorMessage = self.results.isEmpty ? "No results found for \"\(self.query)\"." : nil
            } else {
                self.errorMessage = "No results found for \"\(self.query)\"."
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - Bookmark Logic
    func toggleBookmark(for place: PlaceResult) {
        if let index = savedPlaces.firstIndex(where: { $0.name == place.name && $0.latitude == place.latitude }) {
            savedPlaces.remove(at: index)
        } else {
            savedPlaces.insert(place, at: 0)
        }
        saveBookmarks()
    }
    
    func isBookmarked(_ place: PlaceResult) -> Bool {
        savedPlaces.contains(where: { $0.name == place.name && $0.latitude == place.latitude })
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(savedPlaces) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PlaceResult].self, from: data) {
            savedPlaces = decoded
        }
    }
}
