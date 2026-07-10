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
        HStack(spacing: 4) { 
            Image(systemName: icon)
                .foregroundStyle(Color(.brand))
                .font(.system(size: 14, weight: .bold))
            
            Text(label)
                .font(Theme.Typography.category)
                .foregroundColor(Color(.textPrimary))
        }
        .frame(width: 70, height: 28)
        .background(Color(.background))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGray6).ignoresSafeArea()
        
        HStack(spacing: 12) {
            WeatherChip(icon: "sun.max.fill", label: "16°C")
            WeatherChip(icon: "humidity", label: "59%")
            WeatherChip(icon: "sun.min", label: "1 UV")
        }
    }
}
