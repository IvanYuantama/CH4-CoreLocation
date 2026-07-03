//
//  CoordinateConverter.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import CoreLocation
import MapKit

enum CoordinateConverter {
    /// CLLocationCoordinate2D → "lat,lng" string untuk API query
    static func toString(_ coordinate: CLLocationCoordinate2D) -> String {
        "\(coordinate.latitude),\(coordinate.longitude)"
    }

    /// Buat CLLocationCoordinate2D dari lat dan lng terpisah
    static func make(lat: Double, lng: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// Jarak dalam meter antara dua koordinat
    static func distance(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}
