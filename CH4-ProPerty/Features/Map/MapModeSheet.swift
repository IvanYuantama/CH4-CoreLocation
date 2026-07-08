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

            // MARK: - Tiles
            HStack(spacing: 16) {
                modeTile(
                    title: "Explore",
                    imageName: "explore",
                    isSelected: mapMode == .explore
                ) {
                    mapMode = .explore
                    dismiss()
                }

                modeTile(
                    title: "Satellite",
                    imageName: "satellite",
                    isSelected: mapMode == .satellite
                ) {
                    mapMode = .satellite
                    dismiss()
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func modeTile(
        title: String,
        imageName: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Theme.primary : Color.clear,
                                lineWidth: 3
                            )
                    )

                Text(title)
                    .font(Theme.Typography.section)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            MapModeSheet(mapMode: .constant(.explore))
                .presentationDetents([.height(260)])
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
        }
}
