//
//  LocationManager.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import Foundation
import CoreLocation
import Combine

/// LocationManager membungkus CLLocationManager dan mengekspos semua data
/// sebagai @Published properties sehingga SwiftUI otomatis update UI.
///
/// Konsep Core Location yang dipakai di sini:
/// 1. CLLocationManagerDelegate -> menerima callback lokasi/heading/izin
/// 2. didUpdateLocations         -> data koordinat, altitude, speed, dll
/// 3. didUpdateHeading           -> data arah mata angin (kompas)
/// 4. authorizationStatus        -> status izin akses lokasi
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    // MARK: - Status & Error

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    // MARK: - Lokasi mentah (kalau perlu akses object CLLocation langsung)

    @Published var location: CLLocation?

    // MARK: - Data Koordinat & Sensor Gerak (turunan dari CLLocation)

    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var altitude: Double = 0          // meter di atas permukaan laut (orthometric/MSL)
    @Published var ellipsoidalAltitude: Double = 0 // meter relatif elipsoid WGS84 (iOS 15+)
    @Published var horizontalAccuracy: Double = 0 // radius akurasi horizontal (meter)
    @Published var verticalAccuracy: Double = -1   // radius akurasi vertikal (meter), -1 = altitude tidak valid
    @Published var speed: Double = -1             // m/s, -1 jika tidak valid
    @Published var course: Double = -1            // arah gerak GPS (derajat), -1 jika tidak valid

    // MARK: - Data Heading / Arah Mata Angin (dari sensor kompas magnetik)

    @Published var trueHeading: Double = 0     // arah sebenarnya (relatif kutub utara geografis)
    @Published var magneticHeading: Double = 0 // arah magnetik mentah dari sensor
    @Published var headingAccuracy: Double = 0 // perkiraan deviasi akurasi (derajat)

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1 // hanya update kalau bergerak >= 1 meter
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Permission

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Start / Stop

    func startUpdating() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            startUpdating()
        case .denied, .restricted:
            errorMessage = "Akses lokasi ditolak. Aktifkan lewat Settings > Privacy & Security > Location Services."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation
        latitude = newLocation.coordinate.latitude
        longitude = newLocation.coordinate.longitude
        altitude = newLocation.altitude
        ellipsoidalAltitude = newLocation.ellipsoidalAltitude
        horizontalAccuracy = newLocation.horizontalAccuracy
        verticalAccuracy = newLocation.verticalAccuracy
        speed = newLocation.speed
        course = newLocation.course
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // trueHeading bisa negatif (-1) kalau device tidak bisa menghitung true heading,
        // dalam kondisi itu fallback ke magneticHeading.
        trueHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        magneticHeading = newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }

    // MARK: - Helper: konversi derajat -> nama arah mata angin (Bahasa Indonesia)

    static func cardinalDirection(from degree: Double) -> String {
        let directions = [
            "Utara", "Timur Laut", "Timur", "Tenggara",
            "Selatan", "Barat Daya", "Barat", "Barat Laut"
        ]
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let index = Int((positive + 22.5) / 45) % 8
        return directions[index]
    }

    static func cardinalAbbreviation(from degree: Double) -> String {
        let directions = ["U", "TL", "T", "TG", "S", "BD", "B", "BL"]
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let index = Int((positive + 22.5) / 45) % 8
        return directions[index]
    }
}
