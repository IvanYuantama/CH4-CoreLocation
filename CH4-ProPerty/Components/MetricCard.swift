//
//  MetricCard.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var isReversed: Bool = false // Penentu orientasi
    
    var body: some View {
        HStack(spacing: 12) {
            if !isReversed {
                // Style Kolom Kiri
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.primary)
                    .frame(width: 4, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(Theme.Typography.subtitle).foregroundColor(Theme.textSecondary)
                    Text(value).font(Theme.Typography.section).foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(Theme.primary)
            } else {
                // Style Kolom Kanan (Mirrored)
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(Theme.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(title).font(Theme.Typography.subtitle).foregroundColor(Theme.textSecondary)
                    Text(value).font(Theme.Typography.section).foregroundColor(Theme.textPrimary)
                }
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.primary)
                    .frame(width: 4, height: 40)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        MetricCard(title: "Temperature", value: "Low", icon: "thermometer.medium", isReversed: false)
        MetricCard(title: "Flood Risk", value: "High", icon: "water.waves", isReversed: true)
    }
    .padding()
}
