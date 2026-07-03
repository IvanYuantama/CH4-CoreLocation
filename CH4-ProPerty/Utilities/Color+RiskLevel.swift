//
//  Color+RiskLevel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

// Forward declaration — RiskLevel didefinisikan di Models/Domain/RiskLevel.swift
extension Color {
    /// Warna SwiftUI dari string risk ("low", "medium", "high", "unknown")
    /// Sesuai skema warna backend dari dokumentasi API
    static func forRisk(_ risk: String) -> Color {
        switch risk.lowercased() {
        case "low":    return Color(hex: "#34C759") // Hijau
        case "medium": return Color(hex: "#FF9500") // Oranye
        case "high":   return Color(hex: "#FF3B30") // Merah
        default:       return Color(hex: "#8E8E93") // Abu — unknown
        }
    }

    /// Inisialisasi Color dari hex string
    init(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        let value = UInt64(hexStr, radix: 16) ?? 0
        self.init(
            red:   Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8)  / 255,
            blue:  Double( value & 0x0000FF)         / 255
        )
    }
}
