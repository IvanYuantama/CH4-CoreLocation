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
    
    // Bookmark
    @Published var savedPlaces: [PlaceResult] = []
    private let saveKey = "bookmarked_places_v2"
    
    private var center: CLLocationCoordinate2D?
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadBookmarks()
        
        $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newQuery in
                self?.performSearch(newQuery)
            }
            .store(in: &cancellables)
    }
    
    func setCenter(_ newCenter: CLLocationCoordinate2D) {
        self.center = newCenter
    }
    
    private func performSearch(_ text: String) {
        searchTask?.cancel()
        
        let cleanQuery = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanQuery.isEmpty {
            self.results = []
            self.isLoading = false
            self.errorMessage = nil
            return
        }
        
        self.isLoading = true
        
        searchTask = Task {
            guard let center = self.center else {
                self.isLoading = false
                return
            }
            
            do {
                            let found = try await PlaceSearchService.search(query: cleanQuery, around: center)
                            
                            if Task.isCancelled { return }
                            
                            self.results = Array(found.prefix(6))
                            
                            if self.results.isEmpty {
                                self.errorMessage = "No results found for \"\(cleanQuery)\"."
                            } else {
                                self.errorMessage = nil
                            }
                            
                        } catch {
                            if Task.isCancelled { return }
                            self.errorMessage = "Failed to search location."
                            self.results = []
                        }
            
            if !Task.isCancelled {
                self.isLoading = false
            }
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
