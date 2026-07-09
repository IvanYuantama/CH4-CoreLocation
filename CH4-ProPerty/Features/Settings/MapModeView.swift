//
//  MapModeView.swift
//  CH4-ProPerty
//
//  Created by Ryan Tjendana on 08/07/26.
//

import SwiftUI

struct MapModeView: View {
    @Binding var mapMode: MainMapViewModel.MapMode
    
    // Untuk menutup sheet secara native jika diperlukan via tombol
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // MARK: - Header
            HStack {
                Text("Map Mode")
                    .font(Theme.Typography.title)
                    .foregroundColor(Color(.textPrimary))
                Spacer()
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(Color(.textPrimary))
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // MARK: - Tiles Selection
            HStack(spacing: 20) {
                modeTile(title: "Explore", imageName: "explore", isSelected: mapMode == .explore) {
                    mapMode = .explore
                }
                modeTile(title: "Satellite", imageName: "satellite", isSelected: mapMode == .satellite) {
                    mapMode = .satellite
                }
            }
            .padding(.horizontal, 24)
            
            Spacer() // Mendorong konten ke atas
        }
        .background(Color(.background).ignoresSafeArea()) // Selaras dengan AppModeView
    }

    private func modeTile(title: String, imageName: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 90)
                    .overlay(
                        // TODO: Ganti Image(systemName:) dengan asset gambar (Image("...")) nanti
                        Image(imageName)
                            .resizable()
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.brand), lineWidth: isSelected ? 3 : 0)
                    )

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.textPrimary))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
MapModeView(mapMode: .constant(.explore))
}
