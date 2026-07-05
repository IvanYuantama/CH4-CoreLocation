//
//  MainMapViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import MapKit
import Combine

@MainActor
class MainMapViewModel: ObservableObject {
    static let bali = CLLocationCoordinate2D(latitude: -8.65, longitude: 115.16)
    
    @Published var camera: MapCameraPosition = .region(
        MKCoordinateRegion(center: bali, span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15))
    )
    @Published var mapCenter = bali
    @Published var useHybrid = false
    @Published var showSearch = false
    @Published var pinned: PlaceResult?
    @Published var detail: PlaceResult?
    @Published var bookmarks: Set<String> = []
    
    func updateMapCenter(_ context: MapCameraUpdateContext) {
        mapCenter = context.region.center
    }
    
    func handleMapTap(at coordinate: CLLocationCoordinate2D, origin: CLLocationCoordinate2D) {
        Task {
            guard let place = await ReverseGeocodeService.place(at: coordinate, from: origin) else { return }
            self.pinned = place
            self.detail = place
        }
    }
    
    func selectPlace(_ place: PlaceResult) {
        showSearch = false
        pinned = place
        camera = .region(
            MKCoordinateRegion(center: place.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        )
        
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            self.detail = place
        }
    }
    
    func zoomToUserLocation(_ coordinate: CLLocationCoordinate2D) {
        camera = .region(
            MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        )
    }
}
