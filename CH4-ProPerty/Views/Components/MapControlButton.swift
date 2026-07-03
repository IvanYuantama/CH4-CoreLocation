//
//  MapControlButton.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

struct MapControlButton: View {
    let icon: String
    let action: () -> Void
    var tintColor: Color = .primary

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
