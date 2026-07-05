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

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            bottomBar
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {

            // FIX: Ganti + Text (deprecated iOS 26) dengan string interpolation
            Text("\(Text("Pro").foregroundColor(Theme.primary))Perty")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            HStack(spacing: 8) {
                if viewModel.isWeatherLoading {
                    weatherChip("ellipsis", "—", .secondary)
                        .redacted(reason: .placeholder)
                } else {
                    weatherChip("sun.max.fill",  viewModel.temperature,   .orange)
                    weatherChip("drop.fill",      viewModel.precipitation, .blue)
                    weatherChip("humidity.fill",  viewModel.humidity,      .teal)
                    weatherChip("sun.min.fill",   viewModel.uvIndex,       .yellow)
                }
                Spacer()

                if viewModel.showCompass {
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.visible)
                        .frame(width: 36, height: 36)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if viewModel.show3DToggle {
                    MapControlButton(
                        icon: viewModel.is3DModeActive ? "view.2d" : "view.3d",
                        action: { viewModel.toggle3DMode() }
                    )
                    .frame(width: 36, height: 36)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.show3DToggle)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.showCompass)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func weatherChip(_ icon: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.95), in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 10) {

            // Map Mode button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleMapStyle()
                }
            } label: {
                Image(systemName: viewModel.mapStyleOption.icon)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.black.opacity(0.85), in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }

            // Search bar — tap buka SearchSheet
            Button {
                viewModel.showSearch = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    Text("Search a location").foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "mic.fill").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            // Anchor button
            Button { viewModel.toggleTracking() } label: {
                Image(systemName: viewModel.trackingMode.icon)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(
                        viewModel.trackingMode.isActive ? Theme.primary : Color(.systemGray3),
                        in: Circle()
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
