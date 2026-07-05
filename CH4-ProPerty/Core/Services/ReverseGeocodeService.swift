//
//  ReverseGeocodeService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
import MapKit

enum ReverseGeocodeService {
    static func place(at coordinate: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) async -> PlaceResult? {
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 50, longitudinalMeters: 50)
        request.resultTypes = [.address, .pointOfInterest]
        
        guard let response = try? await MKLocalSearch(request: request).start(),
              let item = response.mapItems.first else {
            return nil
        }

        let name = item.name ?? NSLocalizedString("Selected location", comment: "")
        var subtitle = "Location"
        if let category = item.pointOfInterestCategory?.rawValue {
            subtitle = category.replacingOccurrences(of: "MKPOICategory", with: "")
        }

        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let distanceKm = originLocation.distance(from: item.location) / 1000

        return PlaceResult(
            name: name,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            distanceKm: distanceKm
        )
    }
}
