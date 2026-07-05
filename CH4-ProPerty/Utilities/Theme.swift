//
//  Theme.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

enum Theme {
    // MARK: - Colors
    /// Primary Blue (#2F00EE) - mewakili reliability, trust, calm.
    static let primary = Color(hex: 0x2F00EE)
    
    /// Black & White untuk simplicity dan honesty.
    static let textPrimary = Color.black
    static let textSecondary = Color.black.opacity(0.5) // Untuk deskripsi/subtitle
    static let background = Color.white
    static let cardBackground = Color(UIColor.systemGray6)
    
    // MARK: - Corner Radius
    static let sheetRadius: CGFloat = 30
    static let cardRadius: CGFloat = 10
    
    // MARK: - Typography
    enum Typography {
        static let title = Font.system(size: 20, weight: .bold)     // Bold, 20px
        static let option = Font.system(size: 18, weight: .regular) // Regular, 18px
        static let section = Font.system(size: 16, weight: .medium) // Medium, 16px
        static let category = Font.system(size: 14, weight: .medium)// Medium, 14px
        static let subtitle = Font.system(size: 12, weight: .regular)// Regular, 12px
    }
}

// Helper untuk Hex Color
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
