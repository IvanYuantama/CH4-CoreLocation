//
//  LocationMapView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import SwiftUI
import MapKit

/// Menampilkan peta MapKit dengan posisi pengguna (blue dot) dan kemampuan
/// untuk mengikuti pergerakan pengguna secara otomatis (follow mode).
/// Konsep MapKit yang dipakai:
///   - Map(position:) API baru (iOS 17+) dengan MapCameraPosition
///   - UserAnnotation() untuk menampilkan titik biru lokasi pengguna
///   - MapCompass() & MapScaleView() sebagai kontrol bawaan MapKit
///   - MKCoordinateRegion untuk mengatur area & zoom kamera
struct LocationMapView: View {
    @ObservedObject var locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isFollowingUser = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            // Setiap kali lokasi terbaru berubah, geser kamera kalau mode follow aktif
            .onReceive(locationManager.$location) { newLocation in
                guard isFollowingUser, let newLocation else { return }
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: newLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
            // Kalau pengguna menggeser peta secara manual, matikan mode follow
            .gesture(DragGesture().onChanged { _ in isFollowingUser = false })

            Button {
                isFollowingUser = true
                if let loc = locationManager.location {
                    withAnimation {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: loc.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        )
                    }
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .padding(12)
                    .background(.regularMaterial, in: Circle())
                    .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Peta Lokasi")
    }
}
