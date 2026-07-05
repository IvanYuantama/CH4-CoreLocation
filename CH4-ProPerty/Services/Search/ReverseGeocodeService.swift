//
//  ReverseGeocodeService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

//  Menggantikan MKReverseGeocodingRequest karena CLGeocoder lebih stabil
//  dan mendukung preferredLocale → nama tempat tampil dalam Bahasa Indonesia.
//

import CoreLocation

enum ReverseGeocodeService {

    /// Koordinat → PlaceResult via CLGeocoder (locale id_ID).
    static func place(
        at coordinate: CLLocationCoordinate2D,
        from origin: CLLocationCoordinate2D
    ) async -> PlaceResult? {
        let geocoder = CLGeocoder()
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        guard let placemark = try? await geocoder.reverseGeocodeLocation(
            location,
            preferredLocale: Locale(identifier: "id_ID")  // Nama tempat Bali dalam Bahasa Indonesia
        ).first else { return nil }

        // Pilih nama terbaik yang tersedia
        let name = placemark.name
            ?? placemark.subLocality
            ?? placemark.locality
            ?? NSLocalizedString("Selected location", comment: "")

        // Subtitle tanpa duplikasi
        let parts = [
            placemark.subLocality,
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }
        var seen = Set<String>()
        let subtitle = parts
            .filter { seen.insert($0).inserted }
            .joined(separator: ", ")

        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let distanceKm     = originLocation.distance(from: location) / 1000

        return PlaceResult(
            name:       name,
            subtitle:   subtitle,
            latitude:   coordinate.latitude,
            longitude:  coordinate.longitude,
            distanceKm: distanceKm
        )
    }
}
