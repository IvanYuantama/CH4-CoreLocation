//
//  PointAnalysisResponses.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import Foundation

// MARK: - Root response

struct PointAnalysisResponse: Decodable {
    let success: Bool
    let coordinates: Coordinates
    let overallRisk: String
    let data: [LayerResult]

    enum CodingKeys: String, CodingKey {
        case success, coordinates, data
        case overallRisk = "overall_risk"
    }

    /// Convenience: RiskLevel dari string overallRisk
    var riskLevel: RiskLevel {
        RiskLevel(rawString: overallRisk)
    }
}

// MARK: - Coordinates

struct Coordinates: Decodable {
    let lat: Double
    let lng: Double
}

// MARK: - LayerResult

struct LayerResult: Decodable, Identifiable {
    let layer: String
    let distanceMeters: Int
    let zoneValue: String
    let label: String
    let color: String   // Hex string, e.g. "#FF3B30"
    let risk: String    // "low" | "medium" | "high"

    enum CodingKeys: String, CodingKey {
        case layer, label, color, risk
        case distanceMeters = "distance_meters"
        case zoneValue      = "zone_value"
    }

    /// Identifier unik untuk ForEach
    var id: String { layer }

    /// LayerKey enum dari string layer
    var layerKey: LayerKey? {
        LayerKey(rawValue: layer)
    }

    /// RiskLevel enum dari string risk
    var riskLevel: RiskLevel {
        RiskLevel(rawString: risk)
    }
}
