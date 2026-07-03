//
//  PlaceDescriptor.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import CoreLocation
import MapKit

/// Deskripsi semantik sebuah lokasi — nama, kelurahan, kota, provinsi.
/// Dibuat dari MKMapItem (hasil reverse geocoding) setelah user tap peta.
struct PlaceDescriptor {
    let name: String?
    let shortAddress: String?
    let fullAddress: String?
    let coordinate: CLLocationCoordinate2D

    /// Inisialisasi dari MKMapItem (iOS 26 API)
    init(from item: MKMapItem) {
        self.name        = item.name
        self.shortAddress = item.address?.shortAddress
        self.fullAddress  = item.address?.fullAddress
        self.coordinate  = item.location.coordinate
    }

    /// Display name terbaik yang tersedia
    var displayName: String {
        name ?? shortAddress ?? fullAddress ?? "Selected Location"
    }

    /// Subtitle terbaik yang tersedia
    var subtitle: String? {
        guard let addr = shortAddress ?? fullAddress else { return nil }
        // Hindari duplikasi jika name == address
        return addr == name ? nil : addr
    }
}
