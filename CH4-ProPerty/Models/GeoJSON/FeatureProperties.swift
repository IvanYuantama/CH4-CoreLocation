//
//  FeatureProperties.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import Foundation

struct FeatureProperties: Decodable {
    let layer: String
    let zoneValue: String
    let label: String
    let color: String   // Hex string, e.g. "#FF3B30"
    let risk: String    // "low" | "medium" | "high"

    enum CodingKeys: String, CodingKey {
        case layer, label, color, risk
        case zoneValue = "zone_value"
    }

    var riskLevel: RiskLevel {
        RiskLevel(rawString: risk)
    }
}
