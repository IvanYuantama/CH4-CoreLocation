//
//  CoordinateRegionManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//


//  Mengelola MKCoordinateRegion interaktif:
//  - Initial region saat app pertama buka
//  - Zoom ke koordinat user
//

import MapKit
import CoreLocation

final class CoordinateRegionManager {

    /// Default region: seluruh Bali saat GPS belum tersedia
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -8.4095, longitude: 115.1889),
        span: MKCoordinateSpan(latitudeDelta: 1.2, longitudeDelta: 1.2)
    )

    /// Buat region di sekitar koordinat dengan zoom level tertentu
    func region(
        centeredOn coordinate: CLLocationCoordinate2D,
        spanDelta: Double = 0.05
    ) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
        )
    }

    /// Region zoom dekat (untuk analisis titik)
    func closeRegion(centeredOn coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        region(centeredOn: coordinate, spanDelta: 0.01)
    }
}
