//
//  Theme.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

enum Theme {
    // MARK: - Colors
    static let primary = Color(hex: 0x2F00EE)
    
    static let textPrimary = Color.black
    static let textSecondary = Color.black.opacity(0.5)
    static let background = Color.white
    static let cardBackground = Color(UIColor.systemGray6)
    
    // MARK: - Corner Radius
    static let sheetRadius: CGFloat = 30
    static let cardRadius: CGFloat = 10
    
    // MARK: - Typography
    enum Typography {
        static let title = Font.system(size: 24, weight: .bold)
        static let heading = Font.system(size: 20, weight: .bold)
        static let option = Font.system(size: 18, weight: .regular)
        static let subheading = Font.system(size: 18, weight: .bold)
        static let section = Font.system(size: 16, weight: .medium)
        static let subsection = Font.system(size: 16, weight: .regular)
        static let category = Font.system(size: 14, weight: .regular)
        static let subtitle = Font.system(size: 14, weight: .medium)
        static let text = Font.system(size: 12, weight: .regular)
        static let description = Font.system(size: 12, weight: .medium)
    }
}

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
