//
//  MapModeSheet.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 07/07/26.
//

import SwiftUI

struct MapModeSheet: View {
    @Binding var mapMode: MainMapViewModel.MapMode
    
    // Untuk menutup sheet secara native jika diperlukan via tombol
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // MARK: - Header
            HStack {
                Text("Map Mode")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // MARK: - Tiles Selection
            HStack(spacing: 20) {
                modeTile(title: "Explore", systemImage: "map.fill", isSelected: mapMode == .explore) {
                    mapMode = .explore
                }
                modeTile(title: "Satellite", systemImage: "globe.americas.fill", isSelected: mapMode == .satellite) {
                    mapMode = .satellite
                }
            }
            .padding(.horizontal, 24)
            
            Spacer() // Mendorong konten ke atas
        }
        .background(Theme.background.ignoresSafeArea()) // Selaras dengan AppModeView
    }

    private func modeTile(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 90)
                    .overlay(
                        // TODO: Ganti Image(systemName:) dengan asset gambar (Image("...")) nanti
                        Image(systemName: systemImage)
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.primary, lineWidth: isSelected ? 3 : 0)
                    )

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // Preview menggunakan Text dummy untuk mensimulasikan file MainMapViewModel
    // Asumsi MainMapViewModel.MapMode memiliki enum .explore
    MapModeSheet(mapMode: .constant(.explore))
}
