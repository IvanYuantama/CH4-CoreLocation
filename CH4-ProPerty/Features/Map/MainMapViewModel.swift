//
//  MainMapViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//
//  CHANGELOG (adaptasi behavior anchor/compass/map-mode):
//  - `useHybrid: Bool` diganti `MapMode` enum (.explore/.satellite) supaya bisa dipakai
//    juga untuk state ikon tombol Map Mode.
//  - Tambah `AnchorState` enum (.free/.center/.headingLock) + `handleAnchorTap` sebagai
//    state machine 3 tahap, `handleCompassTap` (jalur keluar alternatif dari Heading-Lock).
//  - Tambah `is3D` + `toggle3D()` untuk tombol 2D/3D (cuma relevan saat mode Satellite).
//  - `zoomToUserLocation` diganti `followLocation(_:heading:)` yang men-gate pergerakan
//    kamera otomatis berdasar anchorState (Free = diabaikan, beda dari behavior lama
//    yang selalu maksa recenter tiap `lastLocation` berubah).
//  - `updateMapCenter` sekarang juga mendeteksi gesture manual user (pan/zoom/rotate)
//    lewat flag `isProgrammaticCameraUpdate`, dan auto-drop ke `.free` sesuai keputusan
//    "manual pan saat Center/Heading-Lock otomatis balik ke Free".
//  - Kamera dibangun lewat `rebuildCamera()`: pakai `.region(...)` yang simpel selama
//    Explore+Free/Center, dan `.camera(MapCamera(...))` begitu butuh heading-lock atau
//    mode Satellite (karena cuma MapCamera yang punya heading & pitch).
//

import SwiftUI
import MapKit
import Combine

@MainActor
class MainMapViewModel: ObservableObject {
    static let bali = CLLocationCoordinate2D(latitude: -8.65, longitude: 115.16)

    enum AnchorState {
        case free
        case center
        case headingLock
    }

    enum MapMode {
        case explore
        case satellite
    }

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

    var mapStyle: MapStyle {
        mapMode == .satellite ? .hybrid : .standard
    }

    // Sumber kebenaran posisi kamera — semua perubahan lewat sini, lalu di-render ke `camera`.
    private var cameraCenter: CLLocationCoordinate2D = bali
    private var cameraDistance: CLLocationDistance = 12_000
    private var cameraHeading: CLLocationDirection = 0

    /// Ditandai `true` sesaat sebelum kita assign `camera` sendiri (recenter/heading-lock/3D),
    /// supaya `updateMapCenter` tahu perubahan ini BUKAN gesture user dan tidak perlu drop ke Free.
    /// Catatan: pendekatan flag seperti ini best-effort — kalau ada animasi programatic yang
    /// tumpang tindih sangat cepat dengan gesture user, ada kemungkinan kecil salah klasifikasi.
    /// Perlu ditest langsung di device.
    private var isProgrammaticCameraUpdate = false

    // MARK: - Map camera change (dipanggil dari `.onMapCameraChange`)
    func updateMapCenter(_ context: MapCameraUpdateContext) {
        mapCenter = context.region.center

        if isProgrammaticCameraUpdate {
            isProgrammaticCameraUpdate = false
            return
        }

        // Heuristik: MapCompass() bawaan Apple tidak expose callback tap sendiri — begitu
        // ditekan, dia langsung reset heading map ke utara (0°) lewat binding `camera`, bukan
        // lewat kode kita. Kalau kita lagi Heading-Lock dan heading yang baru mendadak balik
        // ke ~0 tanpa kita yang gerakin (isProgrammaticCameraUpdate == false), kemungkinan
        // besar itu tap compass -> turun ke Center (bukan Free, sesuai Poin 6 spec).
        // Catatan: heuristik ini best-effort, bisa false-positive kalau user KEBETULAN
        // muter HP dan pas berhenti persis di utara — risikonya kecil & dampaknya ringan.
        if anchorState == .headingLock, abs(context.camera.heading) < 1 {
            anchorState = .center
            cameraHeading = 0
            return
        }

        // Sampai sini berarti perubahan dari gesture user (pan/zoom/rotate manual).
        if anchorState != .free {
            anchorState = .free
        }
    }

    // MARK: - Anchor button: siklus Free -> Center -> Heading-Lock -> Center
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

    /// Dipanggil tiap heading device berubah (sudah di-throttle di LocationManager).
    /// Cuma berefek kalau lagi Heading-Lock.
    func updateHeadingIfLocked(_ heading: CLLocationDirection) {
        guard anchorState == .headingLock else { return }
        moveCamera(to: cameraCenter, heading: heading, animated: false)
    }

    /// Dipanggil tiap `lastLocation` berubah. Beda dari `zoomToUserLocation` versi lama:
    /// sekarang di-gate oleh anchorState — kalau Free, diabaikan (user lagi bebas lihat area lain).
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

    // MARK: - Map Mode (Explore / Satellite)
    func selectMapMode(_ mode: MapMode) {
        mapMode = mode
        if mode == .explore {
            is3D = false // 2D/3D cuma relevan & tampil di Satellite
        }
        rebuildCamera(animated: true)
    }

    func toggle3D() {
        guard mapMode == .satellite else { return }
        is3D.toggle()
        rebuildCamera(animated: true)
    }

    // MARK: - Existing behaviors (tidak berubah secara logika)
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
        anchorState = .free // lokasi hasil search bukan device location, keluar dari siklus anchor
        moveCamera(to: place.coordinate, heading: 0, distance: 6_000, animated: true)

        Task {
            try? await Task.sleep(for: .seconds(0.5))
            self.detail = place
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
            // Butuh MapCamera penuh: Satellite bisa perlu pitch, Heading-Lock butuh rotasi (heading).
            newCamera = .camera(
                MapCamera(
                    centerCoordinate: cameraCenter,
                    distance: cameraDistance,
                    heading: cameraHeading,
                    pitch: pitch
                )
            )
        } else {
            // Explore + Free/Center biasa: region simpel, sama seperti behavior awal.
            let delta = max(0.01, cameraDistance / 111_000) // konversi kasar meter -> derajat span
            newCamera = .region(
                MKCoordinateRegion(
                    center: cameraCenter,
                    span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                )
            )
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                camera = newCamera
            }
        } else {
            camera = newCamera
        }
    }
}
