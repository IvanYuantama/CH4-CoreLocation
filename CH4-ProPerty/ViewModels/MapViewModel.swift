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
enum MapStyleOption: CaseIterable, Equatable {
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

    // FIX: Icon menampilkan MODE SEKARANG (bukan preview berikutnya)
    // — sesuai video Apple Maps yang kamu rekam:
    //   • Saat standard  → tampilkan ikon "map"           (tombol menampilkan state saat ini)
    //   • Saat satellite → tampilkan ikon "globe..."      (tombol menampilkan state saat ini)
    // Behavior ini berbeda dari Apple Maps versi terbaru yang preview mode berikutnya,
    // tapi SESUAI dengan rekaman video kamu (tap → ikon berubah jadi globe saat satellite).
    var icon: String {
        switch self {
        case .standard:  return "map"                        // sedang di standard → ikon map
        case .satellite: return "globe.asia.australia.fill"  // sedang di satellite → ikon globe
        }
    }
}

// MARK: - Tracking Mode
enum TrackingMode: Equatable {
    case none     // location (hollow) — tidak follow
    case follow   // location.fill (biru) — follow tanpa heading
    case heading  // location.north.line.fill — follow + rotate map

    var next: TrackingMode {
        switch self {
        case .none:    return .follow
        case .follow:  return .heading
        case .heading: return .follow   // kembali ke follow, bukan none
        }
    }

    var icon: String {
        switch self {
        case .none:    return "location"
        case .follow:  return "location.fill"
        case .heading: return "location.north.line.fill"
        }
    }

    var isActive: Bool { self != .none }

    // FIX: Properti untuk cek apakah kompas harus ditampilkan (behavior #3 & #5)
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

    // MARK: - Tap & Selection
    var tappedCoordinate: CLLocationCoordinate2D?
    var selectedMapItem: MKMapItem?

    // MARK: - Search
    var searchText: String = ""
    var searchResults: [MKMapItem] = []
    var isSearchActive: Bool = false

    // MARK: - Weather (diisi oleh WeatherManager)
        var temperature: String    = "--°C"
        var precipitation: String  = "-- mm"
        var humidity: String       = "--%"
        
        // 1. Tambahkan variabel untuk ikon cuaca (defaultnya bebas, misal "sun.max.fill")
        var weatherIconName: String = "sun.max.fill"
        
        var isWeatherLoading: Bool = true
        
        // Variabel URL Attribution (sudah kamu tambahkan sebelumnya)
        var attributionLightURL: URL?
        var attributionDarkURL:  URL?
        var attributionPageURL:  URL?

    // MARK: - GeoJSON Layer State
    var activeLayerIDs: Set<LayerKey> = []
    var showLayerFilter: Bool = false
    
    // MARK: - UI Toggles
    var showMapStylePicker: Bool = false

    // MARK: - Computed

    var mapStyle: MapStyle { mapStyleOption.mapStyle }

    /// Tombol 2D/3D hanya tampil saat mode satellite — sesuai Apple Maps
    var show3DToggle: Bool { mapStyleOption == .satellite }

    // FIX: Kompas custom hanya tampil saat trackingMode == .heading (behavior #3 & #5)
    var showCompass: Bool { trackingMode.showsCompass }

    // MARK: - Actions

    /// Toggle Standard ↔ Satellite langsung tanpa popup
    func toggleMapStyle() {
        if mapStyleOption == .satellite {
            is3DModeActive = false
        }
        mapStyleOption = mapStyleOption.toggled
    }

    /// Toggle 3D/2D — hanya berfungsi saat satellite
    func toggle3DMode(currentCenter: CLLocationCoordinate2D? = nil) {
        guard mapStyleOption == .satellite else { return }
        is3DModeActive.toggle()
        let center = currentCenter ?? CLLocationCoordinate2D(latitude: -8.4095, longitude: 115.1889)
        cameraPosition = .camera(MapCamera(
            centerCoordinate: center,
            distance: is3DModeActive ? 800 : 3000,
            heading: 0,
            pitch: is3DModeActive ? 60 : 0
        ))
    }

    /// Toggle anchor: none → follow → heading → follow
    func toggleTracking() {
        trackingMode = trackingMode.next
        switch trackingMode {
        case .none:    break
        case .follow:  cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
        case .heading: cameraPosition = .userLocation(followsHeading: true,  fallback: .automatic)
        }
    }

    /// Dipanggil saat user pan/zoom manual
    func onUserManualPan() {
        // FIX: Saat user geser peta, tracking kembali ke .none (behavior #2)
        // Ikon anchor kembali ke "location" hollow
        trackingMode = .none
    }

    // MARK: - Search

    @MainActor
    func performSearch(in region: MKCoordinateRegion?) async {
        guard !searchText.isEmpty else {
            clearSearch()
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        if let region { request.region = region }

        do {
            let response = try await MKLocalSearch(request: request).start()
            searchResults = response.mapItems
            isSearchActive = !response.mapItems.isEmpty
        } catch {
            searchResults = []
            isSearchActive = false
        }
    }

    func selectSearchResult(_ item: MKMapItem) {
        selectedMapItem = item
        searchText = item.name ?? ""
        isSearchActive = false
        let coord = item.location.coordinate
        tappedCoordinate = coord
        cameraPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearchActive = false
    }

    // MARK: - Weather Actions

        @MainActor
        // 2. Tambahkan parameter 'iconName' ke fungsi ini
        func updateWeather(temp: Double, precipMM: Double, humidityPct: Int, iconName: String) {
            temperature   = "\(Int(temp.rounded()))°C"
            precipitation = "\(String(format: "%.1f", precipMM)) mm"
            humidity      = "\(humidityPct)%"
            weatherIconName = iconName // 3. Simpan nama ikon dari WeatherKit
            isWeatherLoading = false
        }
}
