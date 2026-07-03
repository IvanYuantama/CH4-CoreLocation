//
//  LocationManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import CoreLocation

// MARK: - PENTING: Jangan pakai @MainActor di class level jika implement CLLocationManagerDelegate.
// CLLocationManager memanggil delegate dari background thread.
// Gunakan @Observable saja, lalu update property di MainActor secara eksplisit.

@Observable
final class LocationManager: NSObject {

    // MARK: - State
    var coordinate: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - FIX: Tambah heading property untuk kompas (behavior #1, #3, #5)
    // headingDegrees adalah arah device dalam derajat (0 = Utara, 90 = Timur, dst.)
    var headingDegrees: Double = 0

    // MARK: - Private
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest

        // FIX: Filter 1 derajat agar tidak terlalu sering trigger update
        // Ini penting agar animasi kompas smooth tapi tidak boros baterai
        manager.headingFilter = 1.0

        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }

    func requestOneTimeLocation() {
        manager.requestLocation()
    }

    // FIX: Pisahkan start/stop heading agar bisa dikontrol dari luar
    func startHeadingUpdates() {
        manager.startUpdatingHeading()
    }

    func stopHeadingUpdates() {
        manager.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }

        switch manager.authorizationStatus {
        case .authorizedAlways:
            manager.startMonitoringSignificantLocationChanges()
            // FIX: Mulai heading saat sudah dapat izin always
            manager.startUpdatingHeading()
        case .authorizedWhenInUse:
            manager.requestLocation()
            // FIX: Mulai heading saat sudah dapat izin whenInUse
            manager.startUpdatingHeading()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.coordinate = latest
        }
    }

    // FIX: Implement delegate heading — ini yang bikin kompas bisa berputar (behavior #1, #3, #5)
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // headingAccuracy < 0 artinya kalibrasi gagal, abaikan
        guard newHeading.headingAccuracy >= 0 else { return }

        // Prioritas trueHeading (pakai GPS + magnetometer, lebih akurat dari magneticHeading)
        // Fallback ke magneticHeading jika GPS tidak tersedia (nilai trueHeading = -1)
        let degrees = newHeading.trueHeading >= 0
            ? newHeading.trueHeading
            : newHeading.magneticHeading

        Task { @MainActor in
            self.headingDegrees = degrees
        }
    }

    // FIX: Tampilkan dialog kalibrasi kompas saat akurasi buruk
    // Ini akan muncul otomatis saat magnetometer perlu dikalibrasi (gerak angka 8)
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] \(error.localizedDescription)")
    }
}
