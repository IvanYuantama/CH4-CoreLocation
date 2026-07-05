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
    
    // Nanti kita hubungkan ini ke SettingsMenu
    @State private var showSettings = false

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .top) {
                // 1. Layer Dasar: Peta
                Map(position: $vm.camera) {
                    UserAnnotation()
                    if let pinned = vm.pinned {
                        Marker(pinned.name, coordinate: pinned.coordinate)
                            .tint(Color(red: 0.89, green: 0.22, blue: 0.21)) // Merah Pin
                    }
                }
                .mapStyle(vm.useHybrid ? .hybrid : .standard)
                .onMapCameraChange(frequency: .onEnd) { context in
                    vm.updateMapCenter(context)
                }
                .onTapGesture { screenPoint in
                    guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                    let origin = location.lastLocation ?? vm.mapCenter
                    vm.handleMapTap(at: coordinate, origin: origin)
                }
                .onChange(of: location.lastLocation?.latitude) { _, _ in
                    guard let coordinate = location.lastLocation else { return }
                    vm.zoomToUserLocation(coordinate)
                }
                
                // 2. Layer Atas: Floating Header (Logo & Hamburger Menu)
                HStack(alignment: .top) {
                    // Logo ProPerty
                    Text("\(Text("Pro").foregroundColor(Theme.primary))\(Text("Perty").foregroundColor(Theme.textPrimary))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    // Hamburger Menu Button
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16) // Memberi jarak dari poni/Dynamic Island
                
                // Layer Setting Menu (Akan kita buat nanti)
                // if showSettings { SettingsMenuView() ... }
            }
            // 3. Layer Bawah: Floating Bottom Bar
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
                .presentationCornerRadius(Theme.sheetRadius) // Sesuai Design System
            }
            .sheet(item: $vm.detail) { place in
                PlaceDetailView(place: place)
                    .presentationDetents([.height(400), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(400)))
                    .presentationCornerRadius(Theme.sheetRadius)
            }
        }
    }

    // MARK: - Bottom Floating Bar
    private var bottomFloatingBar: some View {
        HStack(spacing: 12) {
            // Tombol Map Style
            Button {
                vm.useHybrid.toggle()
            } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 50, height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }

            // Tombol Search / Input Tiruan
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
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
            .buttonStyle(.plain)

            // Tombol Locate Me
            Button {
                location.requestLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.primary)
                    .frame(width: 50, height: 50)
                    .background(Color.white)
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
