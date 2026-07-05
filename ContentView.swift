//
//  ContentView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import SwiftUI

/// Layar utama: TabView berisi 3 fitur demo —
/// 1. Peta (MapKit)
/// 2. Kompas / arah mata angin (CLHeading)
/// 3. Detail sensor koordinat (CLLocation)
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        TabView {
            NavigationStack {
                LocationMapView(locationManager: locationManager)
            }
            .tabItem { Label("Peta", systemImage: "map") }

            CompassView(locationManager: locationManager)
                .tabItem { Label("Kompas", systemImage: "safari") }

            NavigationStack {
                CoordinateDetailView(locationManager: locationManager)
            }
            .tabItem { Label("Sensor", systemImage: "location.viewfinder") }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .alert("Lokasi Bermasalah", isPresented: errorBinding) {
            Button("OK", role: .cancel) { locationManager.errorMessage = nil }
        } message: {
            Text(locationManager.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { locationManager.errorMessage != nil },
            set: { isPresented in
                if !isPresented { locationManager.errorMessage = nil }
            }
        )
    }
}

#Preview {
    ContentView()
}
