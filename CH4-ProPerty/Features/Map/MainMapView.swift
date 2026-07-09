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
//  - `bottomFloatingBar` LAMA (HStack: mapMode + searchBar + anchor) DIHAPUS.
//    Sekarang search bar bukan tombol pemicu sheet lagi, tapi jadi bagian docked
//    dari `SearchSheet` itu sendiri (persis Apple Maps) — sheet-nya SELALU present
//    dengan detent kecil (`.height(collapsedSearchHeight)`) sebagai collapsed state,
//    dan naik ke `.medium`/`.large` saat di-tap/drag/focus.
//  - `mapModeButton` & `anchorButton` sekarang jadi floating overlay terpisah
//    (trailing-bottom), mengambang DI ATAS collapsed sheet, karena mereka bukan
//    bagian dari search UI.
//  - `.onChange(of: location.lastLocation?.latitude)` sekarang manggil `vm.followLocation`
//    (di-gate anchorState), bukan `zoomToUserLocation` yang selalu maksa recenter.
//  - Tambah `.onChange(of: location.heading)` buat forward heading (sudah di-throttle)
//    ke `vm.updateHeadingIfLocked`.
//  - Tambah `MapModeSheet` sebagai overlay di root, dengan binding custom yang manggil
//    `vm.selectMapMode(...)` (bukan assignment langsung) supaya efek samping (reset 3D,
//    rebuild kamera) tetap jalan.
//  - UPDATE: `SearchSheet` via `.sheet(isPresented:)` + `PresentationDetents` DIGANTI
//    `FloatingSearchSheet` (FloatingBottomSheet.swift) sebagai overlay custom di dalam
//    ZStack, biar dapet floating card look (bukan native sheet full-width nempel ke
//    bawah layar). State collapsed/expanded sekarang dipegang `searchSheetState`
//    (`FloatingSheetState`) di view ini, ganti peran `vm.searchDetent` (PresentationDetent)
//    yang sebelumnya jadi single source of truth punya native sheet.
//
//  NOTE UNTUK VIEWMODEL (biar kompatibel dengan file ini):
//  - `vm.showSearch: Bool` sudah TIDAK dipakai untuk present/dismiss sheet (sheet-nya
//    sekarang permanent), tapi masih dipertahankan sebagai no-op/legacy jika ada
//    pemanggil lain — boleh dihapus kalau memang sudah tidak direferensikan di tempat lain.
//  - `vm.searchDetent` sudah TIDAK dipakai lagi di file ini (diganti `searchSheetState`
//    lokal), boleh dihapus dari `MainMapViewModel` kalau tidak direferensikan di tempat lain.
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
    @State private var anchorPressed = false
    @State private var mapModePressed = false
    @State private var showMapModeSheet = false
    @Namespace private var mapScope

    // State collapsed/expanded buat FloatingSearchSheet (ganti peran vm.searchDetent).
    @State private var searchSheetState: FloatingSheetState = .collapsed

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .top) {
                // MARK: - Map Layer
                Map(position: $vm.camera, scope: mapScope) {  // ← scope tetap di sini
                    UserAnnotation()
                    if let pinned = vm.pinned {
                        Marker(pinned.name, coordinate: pinned.coordinate)
                            .tint(Color(red: 0.89, green: 0.22, blue: 0.21))
                    }
                }
                .mapScope(mapScope)  // ← PINDAH ke sini, langsung di Map
                .mapStyle(vm.mapStyle)
                .mapControls {
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.automatic)
                    MapPitchToggle(scope: mapScope)
                        .mapControlVisibility(.automatic)
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
                    // Tap di map saat search sheet lagi expanded → collapse dulu,
                    // biar behavior-nya sama kayak Apple Maps (tap map = dismiss keyboard/list).
                    if searchSheetState != .collapsed {
                        withAnimation(.snappy) {
                            searchSheetState = .collapsed
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
                    location.requestLocation()
                }
                .ignoresSafeArea()  // ← tambah ini agar Map full screen

                // MARK: - Blur Header Overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
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
                    Image("app-name")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                        .padding(.top, 10)

                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showSettings.toggle()
                                }
                            } label: {
                                Image(systemName: showSettings ? "xmark" : "line.3.horizontal")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(.textPrimary))
                                    .frame(width: 45, height: 45)
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

                // MARK: - Floating Buttons (Map Mode & Anchor)
                // Mengambang di atas collapsed search sheet, bukan lagi bagian dari
                // bottomFloatingBar lama yang sejajar horizontal sama search bar.
                ZStack(alignment: .bottom) {

                    FloatingSearchSheet(
                        center: vm.mapCenter,
                        state: $searchSheetState,
                        onSelect: vm.selectPlace
                    )

                    if searchSheetState == .collapsed {
                        HStack {

                            MapModeButtonView(vm: vm)

                            Spacer()

                            anchorButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.snappy, value: searchSheetState)
            }
            .sheet(item: $vm.detail) { place in
                PlaceDetailView(place: place)
                    .environmentObject(settings)
                    .presentationDetents([.height(400), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(400)))
                    .presentationCornerRadius(Theme.sheetRadius)
            }
        }
        .environmentObject(settings)
    }
    

    // MARK: - Bottom Map Mode
    private var mapModeButton: some View {
        Button {

            withAnimation(.bouncy(duration: 0.1)){
                mapModePressed.toggle()
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showMapModeSheet = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.bouncy(duration: 0.5)) {
                    mapModePressed = false
                }
            }

        } label: {
            Image(systemName: vm.mapMode == .satellite ? "globe.americas.fill" : "map.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(.textPrimary))
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
                Image(systemName: "magnifyingglass").foregroundColor(Color(.textSecondary))
                Text(L.t(.searchLocation, settings.selectedLanguage)).foregroundColor(Color(.textSecondary))
                    .font(Theme.Typography.section)
                Spacer()
                Image(systemName: "mic.fill").foregroundColor(Color(.textSecondary))
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(UIColor.systemBackground))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)

    }
    
    

    // MARK: - Anchor Button
    private var anchorButton: some View {
        Button {
            withAnimation(.bouncy(duration: 0.18)) {
                anchorPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.bouncy(duration: 0.5)) {
                    anchorPressed = false
                }
            }

            vm.handleAnchorTap(
                currentLocation: location.lastLocation,
                currentHeading: location.heading
            )

            if location.lastLocation == nil {
                location.requestLocation()
            }
        } label: {
            Image(systemName: anchorIconName)
                .font(.system(size: 20))
                .foregroundColor(anchorIconColor)
                .frame(width: 45, height: 45)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .scaleEffect(anchorPressed ? 1.2 : 1.0)
        }
        .buttonStyle(.plain)
        .offset(y: -1)
    }

    private var anchorIconName: String {
        switch vm.anchorState {
        case .free: return "location"
        case .center: return "location.fill"
        case .headingLock: return "location.north.line.fill"
        }
    }

    private var anchorIconColor: Color {
        vm.anchorState == .headingLock ? .blue : Color(.brand)
    }
}

#Preview() {
    MainMapView()
}
