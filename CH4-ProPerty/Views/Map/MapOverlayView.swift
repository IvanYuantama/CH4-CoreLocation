//
//  MapOverlayView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI
import MapKit

struct MapOverlayView: View {
    @Bindable var viewModel: MapViewModel
    var mapScope: Namespace.ID

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top: Weather Pills (pojok kanan atas)
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                if viewModel.isWeatherLoading {
                                    ForEach(0..<3, id: \.self) { _ in
                                        WeatherPill(icon: "ellipsis", text: "---", iconColor: .white.opacity(0.5))
                                            .redacted(reason: .placeholder)
                                    }
                                } else {
                                    // Gunakan ikon dinamis dari WeatherKit!
                                    WeatherPill(icon: viewModel.weatherIconName, text: viewModel.temperature,  iconColor: .yellow)
                                    WeatherPill(icon: "drop.fill",               text: viewModel.precipitation, iconColor: .white)
                                    WeatherPill(icon: "humidity.fill",           text: viewModel.humidity,      iconColor: .white)
                                }
                                
                                // 👇 TAMBAHKAN LOGO ATTRIBUTION DI SINI
                                WeatherAttributionView(
                                    lightURL: viewModel.attributionLightURL,
                                    darkURL: viewModel.attributionDarkURL,
                                    pageURL: viewModel.attributionPageURL
                                )
                                .padding(.top, 4) // Beri sedikit jarak dari kotak cuaca
                                .padding(.trailing, 4)
                            }
                            .padding(.top, 60)
                            .padding(.trailing, 16)
                        }
            Spacer()

            // MARK: - Bottom: Search bar + right controls
            HStack(alignment: .bottom, spacing: 12) {

                // MARK: Search Bar + Dropdown
                VStack(spacing: 0) {
                    if viewModel.isSearchActive && !viewModel.searchResults.isEmpty {
                        searchResultsDropdown
                            .padding(.bottom, 6)
                    }
                    searchBar
                }

                // MARK: Right Controls
                // Urutan bottom → top (VStack menambah item dari atas ke bawah,
                // jadi item pertama = paling atas, item terakhir = paling bawah):
                // Kita balik: anchor paling bawah, kompas paling atas (conditional)
                VStack(spacing: 12) {

                    // [4] Kompas — HANYA muncul saat trackingMode == .heading
                    // Saat heading aktif, map rotate → kompas berputar real-time
                    // Posisi: paling atas dari stack (muncul di atas 2D/3D)
                    if viewModel.trackingMode == .heading {
                        MapCompass(scope: mapScope)
                            .mapControlVisibility(.visible)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }

                    // [3] 2D/3D — hanya muncul saat mode satellite
                    // Posisi: di atas tombol map mode, di bawah kompas
                    if viewModel.show3DToggle {
                        MapControlButton(
                            icon: viewModel.is3DModeActive ? "view.2d" : "view.3d",
                            action: { viewModel.toggle3DMode() }
                        )
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }

                    // [2] Map Mode — toggle Standard ↔ Satellite
                    // Posisi: di atas tombol anchor, di bawah 2D/3D
                    MapControlButton(
                        icon: viewModel.mapStyleOption.icon,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleMapStyle()
                            }
                        }
                    )

                    // [1] Anchor / Navigation — paling bawah
                    // none → follow → heading → follow
                    MapControlButton(
                        icon: viewModel.trackingMode.icon,
                        action: { viewModel.toggleTracking() },
                        tintColor: viewModel.trackingMode.isActive ? .blue : .primary
                    )
                }
                // Animasi saat kompas / 2D/3D muncul dan hilang
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.show3DToggle)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.trackingMode == .heading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            TextField("Search a location", text: $viewModel.searchText)
                .font(.system(size: 16))
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.performSearch(in: nil) }
                }
                .onChange(of: viewModel.searchText) { _, newVal in
                    if newVal.isEmpty { viewModel.clearSearch() }
                }

            if viewModel.searchText.isEmpty {
                Image(systemName: "mic.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    viewModel.clearSearch()
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 2)
    }

    // MARK: - Search Results Dropdown

    private var searchResultsDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.searchResults.prefix(5).enumerated()), id: \.offset) { index, item in
                Button {
                    viewModel.selectSearchResult(item)
                    isSearchFocused = false
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Location")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)

                            if let addr = item.address?.shortAddress {
                                Text(addr)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }

                if index < min(viewModel.searchResults.count, 5) - 1 {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: -3)
    }
}
