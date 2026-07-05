//
//  PlaceSearchService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

import MapKit
import CoreLocation

enum PlaceSearchService {

    static func search(
        query: String,
        around center: CLLocationCoordinate2D
    ) async throws -> [PlaceResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        return try await run(request: request, around: center)
    }

    static func search(
        completion: MKLocalSearchCompletion,
        around center: CLLocationCoordinate2D
    ) async throws -> [PlaceResult] {
        try await run(request: MKLocalSearch.Request(completion: completion), around: center)
    }

    // MARK: - Private

    private static func run(
        request: MKLocalSearch.Request,
        around center: CLLocationCoordinate2D
    ) async throws -> [PlaceResult] {
        let response = try await MKLocalSearch(request: request).start()
        let origin   = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return response.mapItems.map { item in
            // FIX: iOS 26 — item.location non-optional, item.placemark deprecated
            let coord      = item.location.coordinate
            let distanceM  = origin.distance(
                from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            )

            // FIX: Gunakan addressRepresentations dan MKMapItem properties
            // bukan placemark.subAdministrativeArea (deprecated)
            var subtitle = "Location"
            if let category = item.pointOfInterestCategory?.rawValue {
                subtitle = category.replacingOccurrences(of: "MKPOICategory", with: "")
            } else if let name = item.name {
                subtitle = name
            }

            return PlaceResult(
                name:       item.name ?? NSLocalizedString("Unnamed", comment: ""),
                subtitle:   subtitle,
                latitude:   coord.latitude,
                longitude:  coord.longitude,
                distanceKm: distanceM / 1000
            )
        }
    }
}
