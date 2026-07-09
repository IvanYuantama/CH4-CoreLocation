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
    static func place(at coordinate: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) async -> PlaceResult? {
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let originLoc = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let distanceKm = originLoc.distance(from: target) / 1000

        // 1) Coba MKLocalSearch (POI / alamat presisi)
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(center: coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        request.resultTypes = [.address, .pointOfInterest]

        if let response = try? await MKLocalSearch(request: request).start(),
           let item = response.mapItems.first,
           let name = item.name ?? item.address?.shortAddress {
            return PlaceResult(
                name: name,
                subtitle: item.address?.fullAddress ?? "",
                latitude: coordinate.latitude, longitude: coordinate.longitude, distanceKm: distanceKm
            )
        }

        // 2) Fallback: CLGeocoder → nama wilayah administratif (selalu dapat sesuatu)
        let targetLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                if let request = MKReverseGeocodingRequest(location: targetLoc),
                   let mapItems = try? await request.mapItems,
                   let item = mapItems.first {
                    
                    // Di iOS 26, kita langsung menggunakan 'name' dan 'address' bawaan MapKit.
                    // Tidak perlu lagi merangkai subLocality, locality, dll secara manual!
                    let name = item.name ?? item.address?.shortAddress ?? "Selected location"
                    let subtitle = item.address?.fullAddress ?? ""
                    
                    return PlaceResult(
                        name: name,
                        subtitle: subtitle,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        distanceKm: distanceKm
                    )
                }

        // 3) Benar-benar tak ada data → koordinat (jarang terjadi)
        return PlaceResult(
            name: "Selected location",
            subtitle: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude),
            latitude: coordinate.latitude, longitude: coordinate.longitude, distanceKm: distanceKm
        )
    }
}
