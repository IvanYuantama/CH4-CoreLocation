//
//  WeatherPill.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

struct WeatherPill: View {
    let icon: String
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color(red: 0.07, green: 0.07, blue: 0.55).opacity(0.90)))
        .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 2)
    }
}
