//
//  MapContainerView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI
import MapKit

struct MapContainerView: View {

    @State private var viewModel       = MapViewModel()
    @State private var weatherManager  = WeatherManager()
    @State private var locationManager = LocationManager()

    @Namespace private var mapScope

    var body: some View {
        ZStack {

            // MARK: Layer 1 — Base Map (full screen)
            MapReader { proxy in
                Map(position: $viewModel.cameraPosition, scope: mapScope) {
                    UserAnnotation()

                    if let tapped = viewModel.tappedCoordinate {
                        Marker("Selected Location", coordinate: tapped)
                            .tint(.blue)
                    }
                }
                .mapStyle(viewModel.mapStyle)
                .mapControls { MapCompass().mapControlVisibility(.hidden) }
                .ignoresSafeArea()

                // Tap → cari POI atau reverse geocode
                .onTapGesture { screenPoint in
                    guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                    viewModel.tappedCoordinate = coordinate
                    Task { await fetchPlace(at: coordinate) }
                }

                // FIX: Deteksi user geser peta manual → reset tracking ke .none (behavior #2)
                // positionedByUser = true hanya saat USER yang geser, bukan saat kita set programatically
                .onChange(of: viewModel.cameraPosition) { _, position in
                    if position.positionedByUser {
                        viewModel.onUserManualPan()
                    }
                }

                // Lokasi pertama tersedia → fetch weather
                .onChange(of: locationManager.coordinate?.latitude) { _, _ in
                    guard let coord = locationManager.coordinate else { return }
                    Task { await weatherManager.fetch(for: coord, updating: viewModel) }
                }
            }

            // MARK: Layer 2 — SwiftUI Overlay Controls
            // FIX: Pass locationManager agar MapOverlayView bisa akses headingDegrees untuk kompas
            MapOverlayView(
                viewModel: viewModel,
                mapScope: mapScope
            )
        }
        .mapScope(mapScope)
        .mapItemDetailSheet(item: $viewModel.selectedMapItem)
        .onAppear {
            locationManager.requestPermission()
            // FIX: Mulai heading updates saat view muncul
            // (backup — sebenarnya sudah dipanggil dari dalam delegate setelah izin granted)
            locationManager.startHeadingUpdates()
        }
    }

    // MARK: - POI Search + Reverse Geocoding

    private func fetchPlace(at coordinate: CLLocationCoordinate2D) async {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: 50)

        do {
            let response = try await MKLocalSearch(request: request).start()
            let nearest = response.mapItems.min {
                distanceBetween(coordinate, $0.location.coordinate) <
                distanceBetween(coordinate, $1.location.coordinate)
            }
            if let nearest {
                viewModel.selectedMapItem = nearest
                return
            }
        } catch { }

        await fetchAddress(at: coordinate)
    }

    private func fetchAddress(at coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return }
        do {
            viewModel.selectedMapItem = try await request.mapItems.first
        } catch {
            print("[MapContainerView] Geocoding Failed: \(error.localizedDescription)")
        }
    }

    private func distanceBetween(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}

#Preview {
    MapContainerView()
}
