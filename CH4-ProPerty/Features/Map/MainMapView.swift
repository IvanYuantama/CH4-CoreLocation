//
//  MainMapView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//
//  CHANGELOG (adaptasi behavior anchor/compass/map-mode):
//  - Tombol kiri (map.fill) sekarang buka `MapModeSheet` custom overlay (bukan langsung
//    toggle `useHybrid`), ikonnya ikut berubah (map.fill <-> globe.americas.fill).
//  - Tombol kanan (anchor) sekarang manggil `vm.handleAnchorTap(...)`, ikon & warnanya
//    berubah sesuai `vm.anchorState` (Free/Center/Heading-Lock).
//  - `bottomFloatingBar` dibungkus jadi VStack di atas tombol anchor, buat nampung
//    Compass (saat Heading-Lock) & tombol 2D/3D (saat Satellite) yang nempel di atasnya.
//  - `.onChange(of: location.lastLocation?.latitude)` sekarang manggil `vm.followLocation`
//    (di-gate anchorState), bukan `zoomToUserLocation` yang selalu maksa recenter.
//  - Tambah `.onChange(of: location.heading)` buat forward heading (sudah di-throttle)
//    ke `vm.updateHeadingIfLocked`.
//  - Tambah `MapModeSheet` sebagai overlay di root, dengan binding custom yang manggil
//    `vm.selectMapMode(...)` (bukan assignment langsung) supaya efek samping (reset 3D,
//    rebuild kamera) tetap jalan.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine

struct MainMapView: View {
    @StateObject private var vm = MainMapViewModel()
    @StateObject private var location = LocationManager()
    @StateObject private var settings = SettingsViewModel()

    @State private var showSettings = false
    @State private var showMapModeSheet = false
    @Namespace private var mapScope

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .top) {
                // MARK: - Map Layer
                Map(position: $vm.camera, scope: mapScope) {
                    UserAnnotation()
                    if let pinned = vm.pinned {
                        Marker(pinned.name, coordinate: pinned.coordinate)
                            .tint(Color(red: 0.89, green: 0.22, blue: 0.21))
                    }
                }
                .mapStyle(vm.mapStyle)
                .mapControls {
                    // WAJIB di dalam .mapControls{} supaya .automatic benar-benar berfungsi —
                    // sebagai view berdiri sendiri di luar sini (walau scope sama), auto-show
                    // dan tap-to-reset-nya tidak reliable (terbukti dari testing Experiment project).
                    // Konsekuensi: posisi jadi ditentukan sistem, bukan custom di anchorStack lagi.
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.automatic)
                    MapPitchToggle(scope: mapScope)
                        .mapControlVisibility(.automatic)
                    // Disembunyikan — kita pakai anchor button custom sendiri, bukan native ini.
                    MapScaleView(scope: mapScope)
                        .mapControlVisibility(.hidden)
                    MapUserLocationButton(scope: mapScope)
                        .mapControlVisibility(.hidden)
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    vm.updateMapCenter(context)
                }
                .onTapGesture { screenPoint in
                    if showSettings {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showSettings = false
                        }
                        return
                    }
                    guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                    let origin = location.lastLocation ?? vm.mapCenter
                    vm.handleMapTap(at: coordinate, origin: origin)
                }
                .onChange(of: location.lastLocation?.latitude) { _, _ in
                    guard let coordinate = location.lastLocation else { return }
                    vm.followLocation(coordinate, heading: location.heading)
                }
                .onChange(of: location.heading) { _, newHeading in
                    guard let newHeading else { return }
                    vm.updateHeadingIfLocked(newHeading)
                }
                .onAppear {
                    // Minta izin & mulai tracking lokasi+heading sedini mungkin, supaya
                    // saat user tap anchor pertama kali, `lastLocation`/`heading` sudah
                    // (atau segera) tersedia — bukan menunggu tap pertama yang jadi "kebuang".
                    location.requestLocation()
                }

                // MARK: - Blur Header Overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8) // Ketebalan blur yang sudah disesuaikan
                    .frame(height: 140)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .black, .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)

                // MARK: - Top Bar (Logo & Settings)
                ZStack(alignment: .top) {
                    // Logo Asset (Tengah)
                    Image("app-name")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                        .padding(.top, 10)

                    // Tombol Settings (Kanan)
                    HStack {
                        Spacer()

                        // MARK: - Sleek Vertical Dropdown Settings
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showSettings.toggle()
                                }
                            } label: {
                                Image(systemName: showSettings ? "xmark" : "line.3.horizontal")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(width: 45, height: 45) // Ukuran tombol utama
                                    .contentTransition(.symbolEffect(.replace))
                            }

                            if showSettings {
                                SettingsMenuView()
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                            }
                        }
                        .frame(width: 45)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: showSettings ? 16.0 : 22.5))
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .safeAreaInset(edge: .bottom) {
                bottomFloatingBar
            }
            .sheet(isPresented: $showMapModeSheet) {
                MapModeSheet(
                    mapMode: Binding(
                        get: { vm.mapMode },
                        set: { vm.selectMapMode($0) }
                    )
                )
                .presentationDetents([.height(280)])
                .presentationCornerRadius(Theme.sheetRadius)
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $vm.showSearch) {
                // MARK: Pembaruan SearchSheet tanpa parameter bookmarks
                SearchSheet(
                    center: vm.mapCenter,
                    onSelect: vm.selectPlace
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(Theme.sheetRadius)
            }
            .sheet(item: $vm.detail) { place in
                PlaceDetailView(place: place)
                    .environmentObject(settings)
                    .presentationDetents([.height(400), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(400)))
                    .presentationCornerRadius(Theme.sheetRadius)
            }
        }
        .mapScope(mapScope)
        .environmentObject(settings)
    }

    // MARK: - Bottom Floating Bar
    private var bottomFloatingBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            mapModeButton
            searchBar
            anchorButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var mapModeButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showMapModeSheet = true
            }
        } label: {
            Image(systemName: vm.mapMode == .satellite ? "globe.americas.fill" : "map.fill")
                .font(.system(size: 20))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 49, height: 45)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }

    private var searchBar: some View {
        Button {
            vm.showSearch = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.textSecondary)
                Text("Search a location").foregroundColor(Theme.textSecondary)
                    .font(Theme.Typography.section)
                Spacer()
                Image(systemName: "mic.fill").foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(UIColor.systemBackground))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var anchorButton: some View {
        Button {
            vm.handleAnchorTap(currentLocation: location.lastLocation, currentHeading: location.heading)
            if location.lastLocation == nil {
                location.requestLocation() // trigger permission/fetch pertama kalau belum ada fix
            }
        } label: {
            Image(systemName: anchorIconName)
                .font(.system(size: 20))
                .foregroundColor(anchorIconColor)
                .frame(width: 45, height: 45)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }

    private var anchorIconName: String {
        switch vm.anchorState {
        case .free: return "location"
        case .center: return "location.fill"
        case .headingLock: return "location.north.line.fill"
        }
    }

    private var anchorIconColor: Color {
        vm.anchorState == .headingLock ? .blue : Theme.primary
    }
}

#Preview() {
    MainMapView()
}
