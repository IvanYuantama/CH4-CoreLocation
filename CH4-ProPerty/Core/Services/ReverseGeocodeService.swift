//
//  ReverseGeocodeService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
import CoreLocation
import MapKit

enum ReverseGeocodeService {
    /// Koordinat → PlaceResult (nama + alamat) via MapKit (menggantikan CLGeocoder).
    static func place(at coordinate: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) async -> PlaceResult? {
        
        let request = MKLocalSearch.Request()
        // Set center dan span sangat sempit agar pencarian fokus tepat pada titik yang diketuk
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        request.resultTypes = [.address, .pointOfInterest]
        
        guard let response = try? await MKLocalSearch(request: request).start(),
              let mapItem = response.mapItems.first else {
            return nil
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // 🌟 PERBAIKAN 1: Gunakan shortAddress sebagai fallback nama jika mapItem.name kosong
        let name = mapItem.name ?? mapItem.address?.shortAddress ?? "Selected location"

        // 🌟 PERBAIKAN 2: Langsung ambil fullAddress yang sudah diformat rapi oleh Apple
        let subtitle = mapItem.address?.fullAddress ?? ""

        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let distanceKm = originLocation.distance(from: location) / 1000

        return PlaceResult(
            name: name,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            distanceKm: distanceKm
        )
    }
}
