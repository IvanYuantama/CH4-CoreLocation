//
//  MapViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map Style Option
enum MapStyleOption: Equatable {
    case standard
    case satellite

    var toggled: MapStyleOption {
        self == .standard ? .satellite : .standard
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard:  return .standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false)
        case .satellite: return .imagery(elevation: .realistic)
        }
    }

    var icon: String {
        switch self {
        case .standard:  return "map"
        case .satellite: return "globe.asia.australia.fill"
        }
    }
}

// MARK: - Tracking Mode
enum TrackingMode: Equatable {
    case none
    case follow
    case heading

    var next: TrackingMode {
        switch self {
        case .none:    return .follow
        case .follow:  return .heading
        case .heading: return .follow
        }
    }

    var icon: String {
        switch self {
        case .none:    return "location"
        case .follow:  return "location.fill"
        case .heading: return "location.north.line.fill"
        }
    }

    var isActive: Bool  { self != .none }
    var showsCompass: Bool { self == .heading }
}

// MARK: - MapViewModel
@Observable
final class MapViewModel {

    // MARK: - Camera & Map State
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    var mapStyleOption: MapStyleOption = .standard
    var is3DModeActive: Bool = false
    var trackingMode: TrackingMode = .follow

    // Pusat peta saat ini — diupdate via onMapCameraChange (dari teman tim)
    var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: -8.4095, longitude: 115.1889
    )

    // MARK: - Tap & Pin
    var tappedCoordinate: CLLocationCoordinate2D?
    var pinnedPlace: PlaceResult?           // Pin merah di peta
    var selectedPlace: PlaceResult?         // Sheet detail yang terbuka

    // MARK: - Search
    var showSearch: Bool = false
    var bookmarks: Set<String> = []         // Nama lokasi yang di-bookmark

    // MARK: - Weather
    var temperature: String   = "--°C"
    var precipitation: String = "-- mm"
    var humidity: String      = "--%"
    var uvIndex: String       = "-- UV"     // Tambahan dari teman tim
    var isWeatherLoading: Bool = true

    // MARK: - GeoJSON Layer State
    var activeLayerIDs: Set<LayerKey> = []
    var showLayerFilter: Bool = false

    // MARK: - Computed
    var mapStyle: MapStyle   { mapStyleOption.mapStyle }
    var show3DToggle: Bool   { mapStyleOption == .satellite }
    var showCompass: Bool    { trackingMode.showsCompass }

    // MARK: - Map Style
    func toggleMapStyle() {
        if mapStyleOption == .satellite { is3DModeActive = false }
        mapStyleOption = mapStyleOption.toggled
    }

    // MARK: - 3D Toggle
    func toggle3DMode(currentCenter: CLLocationCoordinate2D? = nil) {
        guard mapStyleOption == .satellite else { return }
        is3DModeActive.toggle()
        let center = currentCenter ?? mapCenter
        cameraPosition = .camera(MapCamera(
            centerCoordinate: center,
            distance: is3DModeActive ? 800 : 3000,
            heading: 0,
            pitch: is3DModeActive ? 60 : 0
        ))
    }

    // MARK: - Tracking
    func toggleTracking() {
        trackingMode = trackingMode.next
        switch trackingMode {
        case .none:    break
        case .follow:  cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
        case .heading: cameraPosition = .userLocation(followsHeading: true,  fallback: .automatic)
        }
    }

    func onUserManualPan() { trackingMode = .none }

    // MARK: - Place selection (dari search atau tap peta)

    func select(_ place: PlaceResult) {
        showSearch   = false
        pinnedPlace  = place
        cameraPosition = .region(MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        // Jeda 0.5s agar sheet search sempat menutup dulu
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run { selectedPlace = place }
        }
    }

    func toggleBookmark(_ place: PlaceResult) {
        if bookmarks.contains(place.name) {
            bookmarks.remove(place.name)
        } else {
            bookmarks.insert(place.name)
        }
    }

    // MARK: - Weather update

    @MainActor
    func updateWeather(temp: Double, precipMM: Double, humidityPct: Int, uvIndex: Int) {
        temperature      = "\(Int(temp.rounded()))°C"
        precipitation    = String(format: "%.1f mm", precipMM)
        humidity         = "\(humidityPct)%"
        self.uvIndex     = "\(uvIndex) UV"
        isWeatherLoading = false
    }
}
