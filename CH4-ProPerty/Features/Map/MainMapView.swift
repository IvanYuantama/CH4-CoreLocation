//
//  MainMapView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import CoreLocation
import MapKit

struct MainMapView: View {
    @StateObject private var vm = MainMapViewModel()
    @StateObject private var location = LocationManager()
    @StateObject private var settings = SettingsViewModel()
    
    @State private var showSettings = false
    @State private var anchorPressed = false
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
                .safeAreaPadding(.bottom, vm.detail != nil ? 380 : 0)
                .mapStyle(vm.mapStyle)
                .mapControls {
                    MapScaleView(scope: mapScope).mapControlVisibility(.hidden)
                    MapUserLocationButton(scope: mapScope).mapControlVisibility(.hidden)
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    vm.updateMapCenter(context)
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
                                    .background(Color(.background))
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
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                // MARK: - Floating Search + Controls
                ZStack(alignment: .bottom) {
                    FloatingSearchSheet(
                        center: location.lastLocation ?? vm.mapCenter,
                        state: $searchSheetState,
                        onSelect: vm.selectPlace
                    )
                    .offset(x: 2, y: 35)
                    
                    if searchSheetState == .collapsed {
                        HStack(alignment: .bottom) {
                            MapModeButtonView(vm: vm)
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                
                                if vm.anchorState == .headingLock {
                                    MapCompass(scope: mapScope)
                                        .mapControlVisibility(.visible)
                                        .frame(width: 45, height: 45)
                                        .simultaneousGesture(
                                            TapGesture().onEnded {
                                                withAnimation(.easeInOut) {
                                                    vm.anchorState = .center
                                                }
                                            }
                                        )
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
                vm.clearSelection()
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
    // MARK: - Tombol 2D/3D (Kustom UI + Engine Native)
    private var dimensionButton: some View {
        ZStack {
            MapPitchToggle(scope: mapScope)
                .mapControlVisibility(.visible)
                .frame(width: 45, height: 45)
            
            ZStack {
                Circle().fill(Color(.background))
                
                Text(vm.is3D ? "2D" : "3D")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(.brand))
            }
            .frame(width: 45, height: 45)
            .allowsHitTesting(false)
        }
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
    }
    
    // MARK: - Anchor Button
    private var anchorButton: some View {
        Button {
            withAnimation(.bouncy(duration: 0.18)) { anchorPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.bouncy(duration: 0.5)) { anchorPressed = false }
            }
            
            vm.handleAnchorTap()
            
            if location.lastLocation == nil { location.requestLocation() }
        } label: {
            Image(systemName: anchorIconName)
                .font(.system(size: 20))
                .foregroundColor(anchorIconColor)
                .frame(width: 45, height: 45)
                .background(Color(.background))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
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
        vm.anchorState == .headingLock ? Color("iconBlue") : Color(.iconBlue)
    }}

#Preview() {
    MainMapView()
}
