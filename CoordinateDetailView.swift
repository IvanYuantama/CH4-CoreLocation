//
//  CoordinateDetailView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import SwiftUI
import CoreLocation

/// Menampilkan semua data mentah dari sensor lokasi: koordinat (lat/long),
/// altitude, akurasi, kecepatan, arah gerak, dan status izin.
/// Konsep CoreLocation yang ditonjolkan di sini:
///   - CLLocationCoordinate2D (latitude/longitude)
///   - altitude (ketinggian dari permukaan laut, butuh GPS/barometer)
///   - horizontalAccuracy (radius kepercayaan posisi, dalam meter)
///   - speed & course (hanya valid kalau perangkat sedang bergerak)
struct CoordinateDetailView: View {
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        List {
            Section("Koordinat") {
                detailRow("Latitude", String(format: "%.6f°", locationManager.latitude))
                detailRow("Longitude", String(format: "%.6f°", locationManager.longitude))
                detailRow("Altitude (MSL)", String(format: "%.1f m", locationManager.altitude))
                detailRow("Altitude (Elipsoid)", String(format: "%.1f m", locationManager.ellipsoidalAltitude))
            }

            Section("Akurasi & Gerak") {
                detailRow("Akurasi Horizontal", String(format: "±%.1f m", locationManager.horizontalAccuracy))

                if locationManager.verticalAccuracy >= 0 {
                    detailRow("Akurasi Vertikal", String(format: "±%.1f m", locationManager.verticalAccuracy))
                } else {
                    detailRow("Akurasi Vertikal", "Altitude tidak valid")
                }

                if locationManager.speed >= 0 {
                    detailRow("Kecepatan", String(format: "%.2f m/s (%.1f km/h)",
                                                   locationManager.speed, locationManager.speed * 3.6))
                } else {
                    detailRow("Kecepatan", "Tidak tersedia")
                }

                if locationManager.course >= 0 {
                    detailRow("Arah Gerak (Course)", String(
                        format: "%.0f° (%@)",
                        locationManager.course,
                        LocationManager.cardinalAbbreviation(from: locationManager.course)
                    ))
                } else {
                    detailRow("Arah Gerak (Course)", "Tidak tersedia")
                }
            }

            Section("Status Izin Lokasi") {
                detailRow("Status", authStatusText)
            }

            if let error = locationManager.errorMessage {
                Section("Error") {
                    Text(error).foregroundColor(.red)
                }
            }

            Section {
                Text("Tip: di Simulator, gunakan menu Features > Location di Xcode untuk mensimulasikan koordinat GPS bergerak. Sensor heading/kompas hanya berfungsi di perangkat fisik.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Detail Sensor")
    }

    private var authStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways: return "Diizinkan (Always)"
        case .authorizedWhenInUse: return "Diizinkan (When In Use)"
        case .denied: return "Ditolak"
        case .restricted: return "Dibatasi"
        case .notDetermined: return "Belum ditentukan"
        @unknown default: return "Tidak diketahui"
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}
