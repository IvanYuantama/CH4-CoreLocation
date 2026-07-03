//
//  GeoMathHelpers.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import CoreLocation
import MapKit

enum GeoMathHelpers {
    /// Expand sebuah region dengan faktor tertentu (untuk padding)
    static func expand(_ region: MKCoordinateRegion, by factor: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta:  region.span.latitudeDelta  * factor,
                longitudeDelta: region.span.longitudeDelta * factor
            )
        )
    }

    /// Cek apakah koordinat berada dalam region
    static func contains(
        _ coordinate: CLLocationCoordinate2D,
        in region: MKCoordinateRegion
    ) -> Bool {
        let latOK = abs(coordinate.latitude  - region.center.latitude)  <= region.span.latitudeDelta  / 2
        let lngOK = abs(coordinate.longitude - region.center.longitude) <= region.span.longitudeDelta / 2
        return latOK && lngOK
    }

    /// Default region untuk seluruh Bali
    static let baliRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -8.4095, longitude: 115.1889),
        span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
    )
}
