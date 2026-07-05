//
//  CoordinateSheetView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 01/07/26.
//

import SwiftUI
import CoreLocation

struct CoordinateSheetView: View {
    let coordinate: CLLocationCoordinate2D?
 
    var body: some View {
        VStack(spacing: 16) {
            Text("Lokasi Saya")
                .font(.headline)
 
            if let coordinate {
                VStack(spacing: 8) {
                    LabeledContent("Latitude") {
                        Text("\(coordinate.latitude, specifier: "%.6f")")
                            .monospacedDigit()
                    }
                    Divider()
                    LabeledContent("Longitude") {
                        Text("\(coordinate.longitude, specifier: "%.6f")")
                            .monospacedDigit()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Menunggu data lokasi...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
