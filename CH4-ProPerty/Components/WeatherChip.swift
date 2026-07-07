//
//  WeatherChip.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct WeatherChip: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.brand)
                .font(.system(size: 14))
            
            Text(label)
                .font(Theme.Typography.subtitle)
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        // Background abu-abu agar chip putihnya terlihat jelas
        Color(UIColor.systemGray6).ignoresSafeArea()
        WeatherChip(icon: "thermometer.sun", label: "28°C")
    }
}
