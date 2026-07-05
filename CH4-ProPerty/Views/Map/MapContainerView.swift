//
//  MapContainerView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//


import SwiftUI
import MapKit

struct MapContainerView: View {

    @State private var viewModel        = MapViewModel()
    @State private var weatherManager   = WeatherManager()
    @State private var locationManager  = LocationManager()

    @Namespace private var mapScope

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $viewModel.cameraPosition, scope: mapScope) {
                    UserAnnotation()

                    if let pinned = viewModel.pinnedPlace {
                        Marker(pinned.name, coordinate: pinned.coordinate)
                            .tint(Theme.pin)
                    }
                }
                .mapStyle(viewModel.mapStyle)
                .mapControls { MapCompass().mapControlVisibility(.hidden) }
                .ignoresSafeArea()

                // onMapCameraChange — dari teman tim, lebih baik dari onChange(cameraPosition)
                // Langsung dapat context.region.center tanpa hitung manual
                .onMapCameraChange(frequency: .onEnd) { context in
                    viewModel.mapCenter = context.region.center
                    Task {
                        await weatherManager.fetch(
                            for: context.region.center,
                            updating: viewModel
                        )
                    }
                }
                .task {
                    // Fetch weather pertama kali saat app buka
                    await weatherManager.fetch(for: viewModel.mapCenter, updating: viewModel)
                }

                // Tap peta → reverse geocode → pin + buka detail sheet
                .onTapGesture { screenPoint in
                    guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                    viewModel.tappedCoordinate = coordinate
                    Task { await handleMapTap(at: coordinate) }
                }

                // User geser manual → reset tracking
                .onChange(of: viewModel.cameraPosition) { _, position in
                    if position.positionedByUser { viewModel.onUserManualPan() }
                }

                // Lokasi user tersedia → update mapCenter
                .onChange(of: locationManager.coordinate?.latitude) { _, _ in
                    guard let coord = locationManager.coordinate else { return }
                    Task {
                        await weatherManager.fetch(for: coord, updating: viewModel)
                    }
                }
            }

            // SwiftUI overlay (header + bottom bar + tombol)
            MapOverlayView(viewModel: viewModel, mapScope: mapScope)
        }
        .mapScope(mapScope)

        // Sheet: Search
        .sheet(isPresented: $viewModel.showSearch) {
            SearchSheet(
                center: viewModel.mapCenter,
                bookmarks: $viewModel.bookmarks
            ) { place in
                viewModel.select(place)
            }
            .presentationDetents([.medium, .large])
        }

        // Sheet: Analysis Result
        .sheet(item: $viewModel.selectedPlace) { place in
            AnalysisResultSheet(place: place, weatherManager: weatherManager)
                .presentationDetents([.height(380), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(380)))
        }

        .onAppear {
            locationManager.requestPermission()
            locationManager.startHeadingUpdates()
        }
    }

    // MARK: - Tap handler: ReverseGeocodeService (CLGeocoder, locale id_ID)

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) async {
        let origin = locationManager.coordinate ?? viewModel.mapCenter
        guard let place = await ReverseGeocodeService.place(
            at: coordinate,
            from: origin
        ) else { return }
        await MainActor.run {
            viewModel.pinnedPlace  = place
            viewModel.selectedPlace = place
        }
    }
}

#Preview {
    MapContainerView()
}
