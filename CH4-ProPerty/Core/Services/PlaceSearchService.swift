//
//  PlaceSearchService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
import MapKit

enum PlaceSearchService {
    static func search(query: String, around center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        // Jangkauan pencarian fallback
        request.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0))
        
        return try await run(request: request, around: center)
    }

    static func search(completion: MKLocalSearchCompletion, around center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        try await run(request: MKLocalSearch.Request(completion: completion), around: center)
    }

    private static func run(request: MKLocalSearch.Request, around center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        let response = try await MKLocalSearch(request: request).start()
        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return response.mapItems.map { item in
            // 🌟 PERBAIKAN 1: Gunakan `item.location` langsung, bukan `item.placemark.location`
            let location = item.location
            let coordinate = location.coordinate
            let distanceMeters = origin.distance(from: location)
            
            // 🌟 PERBAIKAN 2: Gunakan API `address` baru iOS 26 untuk mendapatkan alamat yang sudah diformat Apple
            let subtitle = item.address?.fullAddress ?? "Location"

            return PlaceResult(
                // Gunakan shortAddress sebagai cadangan jika name kosong
                name: item.name ?? item.address?.shortAddress ?? NSLocalizedString("Unnamed", comment: ""),
                subtitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                distanceKm: distanceMeters / 1000
            )
        }
    }
}
