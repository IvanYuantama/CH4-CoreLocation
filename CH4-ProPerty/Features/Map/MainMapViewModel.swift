//
//  MainMapViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//
//
//  MainMapViewModel.swift
//  CH4-ProPerty
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

    @Published var camera: MapCameraPosition = .region(
        MKCoordinateRegion(center: bali, span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15))
    )
    @Published var mapCenter = bali
    @Published var mapMode: MapMode = .explore
    @Published var anchorState: AnchorState = .free
    @Published var is3D = false
    @Published var showSearch = false
    @Published var pinned: PlaceResult?
    @Published var detail: PlaceResult?

    /// Dipakai di `.mapStyle(vm.mapStyle)`.
    /// Satellite pakai elevation `.realistic` supaya toggle 2D/3D benar-benar terlihat (flyover).
    var mapStyle: MapStyle {
        switch mapMode {
        case .satellite: return .hybrid(elevation: .realistic)
        case .explore:   return .standard(elevation: .flat)
        }
    }

    // Sumber kebenaran posisi kamera.
    private var cameraCenter: CLLocationCoordinate2D = bali
    private var cameraDistance: CLLocationDistance = 12_000
    private var cameraHeading: CLLocationDirection = 0

    /// Ditandai `true` sesaat sebelum kita assign `camera` sendiri, supaya `updateMapCenter`
    /// tahu perubahan ini BUKAN gesture user (best-effort — perlu tes di device).
    private var isProgrammaticCameraUpdate = false

    // MARK: - Map camera change
    func updateMapCenter(_ context: MapCameraUpdateContext) {
        mapCenter = context.region.center

        if isProgrammaticCameraUpdate {
            isProgrammaticCameraUpdate = false
            return
        }

        // Heuristik tap compass bawaan (reset ke ~0°) saat Heading-Lock → turun ke Center.
        if anchorState == .headingLock, abs(context.camera.heading) < 1 {
            anchorState = .center
            cameraHeading = 0
            return
        }

        // Gesture manual user (pan/zoom/rotate) → keluar dari mode terkunci.
        if anchorState != .free {
            anchorState = .free
        }
    }

    // MARK: - Anchor button: Free -> Center -> Heading-Lock -> Center
    func handleAnchorTap(currentLocation: CLLocationCoordinate2D?, currentHeading: CLLocationDirection?) {
        switch anchorState {
        case .free:
            guard let location = currentLocation else { return }
            anchorState = .center
            moveCamera(to: location, heading: 0, animated: true)

        case .center:
            guard let location = currentLocation else { return }
            anchorState = .headingLock
            moveCamera(to: location, heading: currentHeading ?? 0, animated: true)

        case .headingLock:
            anchorState = .center
            moveCamera(to: cameraCenter, heading: 0, animated: true)
        }
    }

    /// Dipanggil tiap heading device berubah (throttled). Cuma berefek saat Heading-Lock.
    func updateHeadingIfLocked(_ heading: CLLocationDirection) {
        guard anchorState == .headingLock else { return }
        moveCamera(to: cameraCenter, heading: heading, animated: false)
    }

    /// Dipanggil tiap `lastLocation` berubah, di-gate anchorState.
    func followLocation(_ coordinate: CLLocationCoordinate2D, heading: CLLocationDirection?) {
        switch anchorState {
        case .free:
            return
        case .center:
            moveCamera(to: coordinate, heading: 0, animated: true)
        case .headingLock:
            moveCamera(to: coordinate, heading: heading ?? cameraHeading, animated: true)
        }
    }

    /// Tap compass → peta balik ke utara. Kalau Heading-Lock, turun ke Center.
    func resetHeadingNorth() {
        if anchorState == .headingLock { anchorState = .center }
        cameraHeading = 0
        rebuildCamera(animated: true)
    }

    // MARK: - Map Mode (Explore / Satellite)
    func selectMapMode(_ mode: MapMode) {
        mapMode = mode
        if mode == .explore { is3D = false } // 2D/3D cuma relevan di Satellite
        rebuildCamera(animated: true)
    }

    func toggle3D() {
        guard mapMode == .satellite else { return }
        is3D.toggle()
        rebuildCamera(animated: true)
    }

    // MARK: - Pin & selection
    func handleMapTap(at coordinate: CLLocationCoordinate2D, origin: CLLocationCoordinate2D) {
        anchorState = .free // jangan ke-yank balik ke device selama melihat pin
        Task {
            // `origin` selalu device (dipasok dari View) → jarak diukur dari device user.
            guard let place = await ReverseGeocodeService.place(at: coordinate, from: origin) else { return }
            self.pinned = place
            self.moveCamera(to: coordinate, heading: cameraHeading, animated: true) // pindah ke lokasi
            self.detail = place
        }
    }

    func selectPlace(_ place: PlaceResult) {
        showSearch = false
        pinned = place
        anchorState = .free
        moveCamera(to: place.coordinate, heading: 0, distance: 6_000, animated: true)

        Task {
            try? await Task.sleep(for: .seconds(0.5))
            self.detail = place
        }
    }

    /// Sheet detail ditutup → hapus pin & kembalikan anchor/kamera ke device user.
    func clearSelection(device: CLLocationCoordinate2D?) {
        pinned = nil
        detail = nil
        if let device {
            anchorState = .center
            moveCamera(to: device, heading: 0, animated: true) // anchor selalu di titik device
        } else {
            anchorState = .free
        }
    }

    // MARK: - Camera helpers
    private func moveCamera(
        to coordinate: CLLocationCoordinate2D,
        heading: CLLocationDirection,
        distance: CLLocationDistance? = nil,
        animated: Bool
    ) {
        cameraCenter = coordinate
        cameraHeading = heading
        if let distance { cameraDistance = distance }
        rebuildCamera(animated: animated)
    }

    private func rebuildCamera(animated: Bool) {
        isProgrammaticCameraUpdate = true

        let pitch: CLLocationDistance = (mapMode == .satellite && is3D) ? 60 : 0
        let newCamera: MapCameraPosition

        if mapMode == .satellite || anchorState == .headingLock {
            newCamera = .camera(
                MapCamera(
                    centerCoordinate: cameraCenter,
                    distance: cameraDistance,
                    heading: cameraHeading,
                    pitch: pitch
                )
            )
        } else {
            let delta = max(0.01, cameraDistance / 111_000)
            newCamera = .region(
                MKCoordinateRegion(
                    center: cameraCenter,
                    span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                )
            )
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.5)) { camera = newCamera }
        } else {
            camera = newCamera
        }
    }
}
