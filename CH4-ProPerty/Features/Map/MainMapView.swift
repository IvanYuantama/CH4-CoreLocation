//
//  MainMapView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import MapKit

struct MainMapView: View {
    @StateObject private var vm = MainMapViewModel()
    @StateObject private var location = LocationManager()
    @StateObject private var settings = SettingsViewModel()
    
    @State private var showSettings = false

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .top) {
                Map(position: $vm.camera) {
                    UserAnnotation()
                    if let pinned = vm.pinned {
                        Marker(pinned.name, coordinate: pinned.coordinate)
                            .tint(Color(red: 0.89, green: 0.22, blue: 0.21))
                    }
                }
                .mapStyle(vm.useHybrid ? .hybrid : .standard)
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
                    vm.zoomToUserLocation(coordinate)
                }
                
                HStack(alignment: .top) {
                    Text("\(Text("Pro").foregroundColor(Theme.primary))\(Text("Perty").foregroundColor(Theme.textPrimary))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .padding(.top, 4)
                        .padding(.leading, 130)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSettings.toggle()
                            }
                        } label: {
                            Image(systemName: showSettings ? "xmark" : "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                                .frame(width: 45, height: 45)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                                .animation(.easeInOut(duration: 0.2), value: showSettings)
                        }
                        
                        if showSettings {
                            SettingsMenuView()
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .safeAreaInset(edge: .bottom) {
                bottomFloatingBar
            }
            .sheet(isPresented: $vm.showSearch) {
                SearchSheet(
                    center: vm.mapCenter,
                    bookmarks: $vm.bookmarks,
                    onSelect: vm.selectPlace
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(Theme.sheetRadius)
            }
            .sheet(item: $vm.detail) { place in
                PlaceDetailView(place: place)
                    .environmentObject(settings) // ← INJECT SETTINGS
                    .presentationDetents([.height(400), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(400)))
                    .presentationCornerRadius(Theme.sheetRadius)
            }
        }
        .environmentObject(settings)
    }

    // MARK: - Bottom Floating Bar
    private var bottomFloatingBar: some View {
        HStack(spacing: 12) {
            Button {
                vm.useHybrid.toggle()
            } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 49, height: 45)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }

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

            Button {
                location.requestLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primary)
                    .frame(width: 45, height: 45)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
#Preview() {
    MainMapView()
}
