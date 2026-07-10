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
    @Published var searchDetent: PresentationDetent = .height(64)
    static let bali = CLLocationCoordinate2D(latitude: -8.65, longitude: 115.16)

    enum AnchorState { case free, center, headingLock }
    enum MapMode { case explore, satellite }

    @Published var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @Published var mapCenter = bali
    @Published var mapMode: MapMode = .explore
    @Published var anchorState: AnchorState = .center
    @Published var is3D = false
    @Published var showSearch = false
    @Published var pinned: PlaceResult?
    @Published var detail: PlaceResult?
    @Published var currentDistance: CLLocationDistance = 6000

    var mapStyle: MapStyle {
        switch mapMode {
        case .satellite: return .hybrid(elevation: .realistic)
        case .explore:   return .standard(elevation: .flat)
        }
    }

    // MARK: - Map camera change
    func updateMapCenter(_ context: MapCameraUpdateContext) {
            mapCenter = context.region.center

            is3D = context.camera.pitch > 10
            
            currentDistance = context.camera.distance

            if camera.positionedByUser && anchorState != .free {
                anchorState = .free
            }
        }
    // MARK: - Anchor button: Free -> Center -> Heading-Lock -> Center
    func handleAnchorTap() {
        switch anchorState {
        case .free, .headingLock:
            anchorState = .center
            withAnimation(.easeInOut) {
                camera = .userLocation(followsHeading: false, fallback: .automatic)
            }
            
        case .center:
            anchorState = .headingLock
            withAnimation(.easeInOut) {
                camera = .userLocation(followsHeading: true, fallback: .automatic)
            }
        }
    }

    // MARK: - Map Mode (Explore / Satellite)
    func selectMapMode(_ mode: MapMode) {
        mapMode = mode
    }

    // MARK: - Pin & selection
    func handleMapTap(at coordinate: CLLocationCoordinate2D, origin: CLLocationCoordinate2D) {
            anchorState = .free
            Task {
                guard let place = await ReverseGeocodeService.place(at: coordinate, from: origin) else { return }
                self.pinned = place
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.camera = .camera(MapCamera(
                        centerCoordinate: coordinate,
                        distance: self.currentDistance
                    ))
                }
                
                try? await Task.sleep(for: .seconds(0.5))
                self.detail = place
            }
        }

    func selectPlace(_ place: PlaceResult) {
        showSearch = false
        pinned = place
        anchorState = .free
                
                camera = .region(MKCoordinateRegion(
                    center: place.coordinate,
                    latitudinalMeters: 6000,
                    longitudinalMeters: 6000
                ))

                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    self.detail = place
                }
            }

    func clearSelection() {
        pinned = nil
        detail = nil
        anchorState = .free
    }
}
