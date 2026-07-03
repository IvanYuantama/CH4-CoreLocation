//
//  UIColor+Hex.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import UIKit

extension UIColor {
    /// Membuat UIColor dari hex string (dengan atau tanpa #)
    /// Contoh: UIColor(hex: "#FF3B30") atau UIColor(hex: "FF3B30")
    /// Dipakai oleh GeoJSONOverlayManager untuk warna polygon dari backend
    convenience init?(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }

        guard hexStr.count == 6,
              let value = UInt64(hexStr, radix: 16) else { return nil }

        self.init(
            red:   CGFloat((value & 0xFF0000) >> 16) / 255,
            green: CGFloat((value & 0x00FF00) >> 8)  / 255,
            blue:  CGFloat( value & 0x0000FF)         / 255,
            alpha: 1.0
        )
    }
}
