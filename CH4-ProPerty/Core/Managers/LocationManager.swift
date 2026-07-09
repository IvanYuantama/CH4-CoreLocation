//
//  LocationManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//
//  CHANGELOG (adaptasi behavior anchor/compass):
//  - Tambah `heading` published property + `CLLocationManagerDelegate` untuk `didUpdateHeading`.
//  - `manager.headingFilter = 3` -> throttle, compass/kamera cuma update kalau heading
//    berubah minimal 3 derajat (sesuai keputusan: "perlu throttle").
//  - `didUpdateLocations` TIDAK lagi memanggil `stopUpdatingLocation()`. Sebelumnya location
//    cuma one-shot fetch, padahal state Center & Heading-Lock butuh kamera terus mengikuti
//    device selama user bergerak.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var heading: CLLocationDirection?
    @Published var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.headingFilter = 3 // derajat — throttle update heading
    }

    /// Dipanggil dari tombol anchor / saat app butuh trigger permission.
    /// Kalau sudah authorized, ini juga yang menyalakan continuous tracking
    /// (lokasi + heading) yang dipakai terus-menerus oleh state Center/Heading-Lock.
    func requestLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            errorMessage = NSLocalizedString("Location permission denied. Enable it in Settings.", comment: "")
        default:
            startTracking()
        }
    }
    private func startTracking() {
        manager.requestTemporaryFullAccuracyAuthorization(
            withPurposeKey: "PropertyAnalysis"
        )
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    /// Belum dipanggil di mana pun saat ini — disediakan kalau nanti butuh
    /// hemat baterai (mis. saat app masuk background).
    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startTracking()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.lastLocation = coordinate
            // Sengaja tidak stopUpdatingLocation() lagi di sini — lihat CHANGELOG di atas.
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // trueHeading bisa -1 kalau belum valid (butuh kalibrasi/device diam) -> fallback magnetic.
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.heading = value
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = String(format: NSLocalizedString("Failed to get location: %@", comment: ""), error.localizedDescription)
        }
    }
}
