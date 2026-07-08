//
//  PlaceResult.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
import CoreLocation

struct PlaceResult: Identifiable, Equatable, Codable {
    var id = UUID()
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var distanceLabel: String? {
        guard let distanceKm else { return nil }
        // Format: Jika di bawah 10km ada koma (1.7 km), jika di atas 10km bulat (56 km)
        return distanceKm < 10
            ? String(format: "%.1f km", distanceKm)
            : "\(Int(distanceKm.rounded())) km"
    }

    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool { lhs.id == rhs.id }
}
