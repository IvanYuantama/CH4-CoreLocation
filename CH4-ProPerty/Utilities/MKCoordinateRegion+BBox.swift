//
//  MKCoordinateRegion+BBox.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import MapKit

extension MKCoordinateRegion {
    /// Konversi region ke format bbox string untuk query parameter backend:
    /// GET /api/layers/:key?bbox=west,south,east,north
    func toBboxString() -> String {
        let west  = center.longitude - span.longitudeDelta / 2
        let east  = center.longitude + span.longitudeDelta / 2
        let south = center.latitude  - span.latitudeDelta  / 2
        let north = center.latitude  + span.latitudeDelta  / 2
        return "\(west),\(south),\(east),\(north)"
    }

    /// Bbox dibulatkan 2 desimal — untuk cache key
    /// Mencegah fetch ulang saat user scroll sedikit (< ~1km)
    func toBboxCacheKey() -> String {
        let west  = center.longitude - span.longitudeDelta / 2
        let east  = center.longitude + span.longitudeDelta / 2
        let south = center.latitude  - span.latitudeDelta  / 2
        let north = center.latitude  + span.latitudeDelta  / 2
        return String(format: "%.2f,%.2f,%.2f,%.2f", west, south, east, north)
    }
}
