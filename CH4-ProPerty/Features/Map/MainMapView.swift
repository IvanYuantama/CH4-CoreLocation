//
//  MainMapView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
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
    @State private var mapHeading: CLLocationDirection = 0   // heading peta untuk compass (live)
    @Namespace private var mapScope

    @State private var searchSheetState: FloatingSheetState = .collapsed

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .top) {
                // MARK: - Map Layer
                Map(position: $vm.camera, scope: mapScope) {
                    UserAnnotation()
                    if let pinned = vm.pinned {
                        Annotation(pinned.name, coordinate: pinned.coordinate, anchor: .bottom) {
                            CustomPinMarker()
                        }
                    }
                }
                .mapStyle(vm.mapStyle)
                .mapControls {
                    MapScaleView(scope: mapScope).mapControlVisibility(.hidden)
                    MapUserLocationButton(scope: mapScope).mapControlVisibility(.hidden)
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    vm.updateMapCenter(context)
                }
                .onMapCameraChange(frequency: .continuous) { context in
                    mapHeading = context.camera.heading   // compass real-time (smooth)
                }
                .onTapGesture { screenPoint in
                    if showSettings {
                        withAnimation(.easeOut(duration: 0.2)) { showSettings = false }
                        return
                    }
                    if searchSheetState != .collapsed {
                        withAnimation(.snappy) { searchSheetState = .collapsed }
                        return
                    }
                    guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                    let origin = location.lastLocation ?? vm.mapCenter   // jarak dari device
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

                // MARK: - Blur Header Overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(height: 140)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .black, .clear]),
                            startPoint: .top, endPoint: .bottom
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

                // MARK: - Floating Search + Controls
                ZStack(alignment: .bottom) {
                    FloatingSearchSheet(
                        center: location.lastLocation ?? vm.mapCenter,   // jarak hasil search dari device
                        state: $searchSheetState,
                        onSelect: vm.selectPlace
                    )
                    .offset(x: 2, y: 35)

                    if searchSheetState == .collapsed {
                        HStack(alignment: .bottom) {
                            MapModeButtonView(vm: vm)

                            Spacer()

                            VStack(spacing: 12) {
                                CompassView(heading: mapHeading) {
                                    vm.resetHeadingNorth()
                                    mapHeading = 0
                                }
                                if vm.mapMode == .satellite {
                                    dimensionButton
                                }
                                anchorButton
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.snappy, value: searchSheetState)
            }
            .sheet(item: $vm.detail, onDismiss: {
                vm.clearSelection(device: location.lastLocation)   // pin hilang + anchor balik device
            }) { place in
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

    // MARK: - Tombol 2D/3D (Satellite) — behavior Apple Maps
    private var dimensionButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.4)) { vm.toggle3D() }
        } label: {
            Text(vm.is3D ? "2D" : "3D")   // label = aksi berikutnya
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(.brand))
                .frame(width: 45, height: 45)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Anchor Button
    private var anchorButton: some View {
        Button {
            withAnimation(.bouncy(duration: 0.18)) { anchorPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.bouncy(duration: 0.5)) { anchorPressed = false }
            }
            vm.handleAnchorTap(
                currentLocation: location.lastLocation,
                currentHeading: location.heading
            )
            if location.lastLocation == nil { location.requestLocation() }
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
