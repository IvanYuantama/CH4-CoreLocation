//
//  PlaceResult.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

import CoreLocation

/// Hasil pencarian / reverse geocode sebuah lokasi.
/// Dipakai di SearchSheet, SearchResultRow, dan AnalysisResultSheet.
struct PlaceResult: Identifiable, Equatable, Codable {

    // UUID non-persisten — OK karena tidak perlu disimpan antar sesi
    let id: UUID
    let name: String
    let subtitle: String       // "Kabupaten Badung, Bali, Indonesia"
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?    // Jarak dari user, nil jika lokasi tidak tersedia

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        latitude: Double,
        longitude: Double,
        distanceKm: Double? = nil
    ) {
        self.id          = id
        self.name        = name
        self.subtitle    = subtitle
        self.latitude    = latitude
        self.longitude   = longitude
        self.distanceKm  = distanceKm
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Label jarak yang tampil di SearchResultRow (e.g. "1.7 km", "56 km")
    var distanceLabel: String? {
        guard let distanceKm else { return nil }
        return distanceKm < 10
            ? String(format: "%.1f km", distanceKm)
            : "\(Int(distanceKm.rounded())) km"
    }

    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool {
        lhs.id == rhs.id
    }
}
