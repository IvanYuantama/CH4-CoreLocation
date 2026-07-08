//
//  BookmarkManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 08/07/26.
//

import SwiftUI
import Combine

class BookmarkManager: ObservableObject {
    @Published var savedPlaces: [PlaceResult] = []
    
    private let saveKey = "bookmarked_places"
    
    init() {
        loadBookmarks()
    }
    
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
