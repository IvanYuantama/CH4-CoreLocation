//
//  MapModeSheet.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 07/07/26.
//

import SwiftUI

struct MapModeSheet: View {
    @Binding var mapMode: MainMapViewModel.MapMode
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang: String = "en"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text(L.t(.mapMode, lang))
                    .font(Theme.Typography.title)
                    .foregroundColor(Color(.textPrimary))
                Spacer()
                Image(systemName: "map").font(.title2).foregroundColor(Color(.textPrimary))
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            HStack(spacing: 20) {
                modeTile(title: L.t(.explore, lang), imageName: "explore", isSelected: mapMode == .explore) {
                    mapMode = .explore
                }
                modeTile(title: L.t(.satellite, lang), imageName: "satellite", isSelected: mapMode == .satellite) {
                    mapMode = .satellite
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color(.background).ignoresSafeArea())
    }

    private func modeTile(title: String, imageName: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 90)
                    .overlay(
                        // Gunakan gambar kustom dari Assets
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
    MapModeSheet(mapMode: .constant(.explore))
}
