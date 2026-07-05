//
//  CompassView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import SwiftUI
import CoreLocation

/// Tampilan kompas visual berdasarkan data heading dari CoreLocation.
/// Konsep yang dipakai: CLHeading.trueHeading & magneticHeading, lalu
/// divisualisasikan sebagai dial yang berputar berlawanan arah agar jarum
/// (segitiga merah) selalu menunjuk ke arah hadap device.
struct CompassView: View {
    @ObservedObject var locationManager: LocationManager

    private let cardinalMarks: [(label: String, degree: Double, isMain: Bool)] = [
        ("U", 0, true), ("TL", 45, false), ("T", 90, true), ("TG", 135, false),
        ("S", 180, true), ("BD", 225, false), ("B", 270, true), ("BL", 315, false)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Kompas (Arah Mata Angin)")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 260, height: 260)

                // Dial label arah, berputar berlawanan dengan trueHeading
                // sehingga "U" selalu menunjuk ke utara geografis yang benar.
                ForEach(cardinalMarks, id: \.label) { mark in
                    Text(mark.label)
                        .font(.system(size: mark.isMain ? 18 : 12, weight: mark.isMain ? .bold : .regular))
                        .foregroundColor(mark.isMain ? .primary : .secondary)
                        .offset(y: -115)
                        .rotationEffect(.degrees(mark.degree))
                }
                .rotationEffect(.degrees(-locationManager.trueHeading))

                // Jarum penunjuk: selalu menghadap ke atas, mewakili arah hadap iPhone
                Image(systemName: "location.north.fill")
                    .resizable()
                    .frame(width: 34, height: 34)
                    .foregroundColor(.red)

                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 260, height: 260)

            VStack(spacing: 4) {
                Text("\(Int(locationManager.trueHeading))°")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text(LocationManager.cardinalDirection(from: locationManager.trueHeading))
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                infoChip(title: "True Heading", value: String(format: "%.1f°", locationManager.trueHeading))
                infoChip(title: "Magnetic", value: String(format: "%.1f°", locationManager.magneticHeading))
                infoChip(title: "Akurasi", value: String(format: "±%.1f°", locationManager.headingAccuracy))
            }

            if !CLCompassAvailable {
                Text("Perangkat ini tidak mempunyai sensor kompas (magnetometer).")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
    }

    private var CLCompassAvailable: Bool {
        CLLocationManager.headingAvailable()
    }

    private func infoChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).fontWeight(.semibold)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
