//
//  RiskLevel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

enum RiskLevel: String, CaseIterable {
    case low     = "low"
    case medium  = "medium"
    case high    = "high"
    case unknown = "unknown"

    /// Warna hex sesuai dokumentasi backend
    var hexColor: String {
        switch self {
        case .low:     return "#34C759"
        case .medium:  return "#FF9500"
        case .high:    return "#FF3B30"
        case .unknown: return "#8E8E93"
        }
    }

    var color: Color { Color(hex: hexColor) }

    var label: String {
        switch self {
        case .low:     return "Low Risk"
        case .medium:  return "Medium Risk"
        case .high:    return "High Risk"
        case .unknown: return "Unknown"
        }
    }

    /// Inisialisasi dari string response backend
    init(rawString: String) {
        self = RiskLevel(rawValue: rawString.lowercased()) ?? .unknown
    }
}
