//
//  MapControlBar.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 08/07/26.
//

import SwiftUI

struct MapControlBar: View {
    let mapMode: MainMapViewModel.MapMode
    let anchorIconName: String
    let anchorIconColor: Color
    let onMapModeTap: () -> Void
    let onSearchTap: () -> Void
    let onAnchorTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Tombol Map Mode
            Button(action: onMapModeTap) {
                Image(systemName: mapMode == .satellite ? "globe.americas.fill" : "map.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(.textPrimary))
                    .frame(width: 50, height: 50)
                    .background(.thickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            // Search Bar
            Button(action: onSearchTap) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(.textSecondary))
                    Text("Cari lokasi...")
                        .foregroundColor(Color(.textSecondary))
                        .font(Theme.Typography.section)
                    Spacer()
                    Image(systemName: "mic.fill")
                        .foregroundColor(Color(.textSecondary))
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(.thickMaterial)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Tombol Anchor (GPS)
            Button(action: onAnchorTap) {
                Image(systemName: anchorIconName)
                    .font(.system(size: 20))
                    .foregroundColor(anchorIconColor)
                    .frame(width: 50, height: 50)
                    .background(.thickMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
