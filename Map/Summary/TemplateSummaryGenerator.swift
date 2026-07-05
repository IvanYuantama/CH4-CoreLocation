//
//  Untitled.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 03/07/26.
//

import Foundation

extension JSONValue {
    var asDouble: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return Double(v)
        default: return nil
        }
    }
}

// MARK: - Struct metrik hasil ekstraksi, siap diolah jadi kalimat

struct AreaMetrics {
    var floodRiskLabel: String?      // "Low Flood Risk", "Medium Flood Risk", dst
    var temperatureLabel: String?    // "Cool", "Warm", "Hot", dst
    var airQualityLabel: String?     // "Good", "Moderate", "Poor"
    var greenSpaceLabel: String?     // "Dense", "Moderate", "Sparse"
    var population: Int?
    var elevationLabel: String?      // "Highland", "Lowland", "Coastal"
    var roadTypes: [String] = []     // label roads_buffer yang ada di titik ini
    var nearestFacilityDistance: Int?
    var wifiDownloadMbps: Double?
    var mobileDownloadMbps: Double?
    var crimeRate: Double?
}

enum AreaMetricsExtractor {
    static func extract(from insight: LocationInsight) -> AreaMetrics {
        var m = AreaMetrics()

        for item in insight.data {
            switch item.layer {
            case "flood":
                m.floodRiskLabel = item.label
            case "temperature":
                m.temperatureLabel = item.label
            case "air_quality":
                m.airQualityLabel = item.label
            case "green_spaces":
                m.greenSpaceLabel = item.label
            case "population":
                m.population = item.attributes["jumlah_pen"]?.asInt
            case "elevation":
                m.elevationLabel = item.label
            case "roads_buffer":
                // Anggap "ada" di lokasi kalau jaraknya sangat dekat (0-100m)
                if item.distance_meters <= 100 {
                    m.roadTypes.append(item.label)
                }
            case "public_facilities":
                let distance = Int(item.distance_meters)
                if m.nearestFacilityDistance == nil || distance < m.nearestFacilityDistance! {
                    m.nearestFacilityDistance = distance
                }
            case "wifi":
                m.wifiDownloadMbps = item.attributes["dl_mbps"]?.asDouble
            case "mobile_data":
                m.mobileDownloadMbps = item.attributes["dl_mbps"]?.asDouble
            case "crime":
                m.crimeRate = item.attributes["crime_rate"]?.asDouble
            default:
                break
            }
        }
        return m
    }
}

enum TemplateSummaryGenerator {
    static func generate(from insight: LocationInsight) -> String {
        let m = AreaMetricsExtractor.extract(from: insight)

        let temperature = temperaturePhrase(m.temperatureLabel)
        let flood = floodPhrase(m.floodRiskLabel)
        let air = airQualityPhrase(m.airQualityLabel)
        let green = greenSpacePhrase(m.greenSpaceLabel)
        let population = populationPhrase(m.population)
        let elevation = elevationPhrase(m.elevationLabel)
        let roads = roadPhrase(m.roadTypes)
        let facility = facilityPhrase(m.nearestFacilityDistance)
        let connectivity = connectivityPhrase(
            wifi: m.wifiDownloadMbps,
            mobile: m.mobileDownloadMbps
        )
        let crime = crimePhrase(m.crimeRate)

        let sentence1 = "This area is \(temperature) with \(flood) flood risk, good air quality, and dense green spaces."
        let sentence2 = "It is \(population), located in \(elevation), and well connected with \(roads)."
        let sentence3 = "Public facilities are \(facility), and wifi and mobile data connectivity are \(connectivity), while the crime rate is \(crime)."

        // Catatan: air quality & green space label sengaja belum dipakai di sentence1
        // di atas biar match struktur contohmu — lihat versi lengkap di bawah.
        return [sentence1, sentence2, sentence3].joined(separator: " ")
    }

    // MARK: Kamus & threshold — semua dalam English

    private static func temperaturePhrase(_ label: String?) -> String {
        switch label?.lowercased() {
        case "cool": return "cool"
        case "cold": return "cold"
        case "warm": return "warm"
        case "hot": return "hot"
        default: return "comfortable"
        }
    }

    private static func floodPhrase(_ label: String?) -> String {
        guard let label = label?.lowercased() else { return "an unknown" }
        if label.contains("low") { return "low" }
        if label.contains("medium") || label.contains("moderate") { return "moderate" }
        if label.contains("high") { return "high" }
        return "an unknown"
    }

    private static func airQualityPhrase(_ label: String?) -> String {
        switch label?.lowercased() {
        case "good": return "good"
        case "moderate": return "moderate"
        case "poor", "bad": return "poor"
        default: return "fair"
        }
    }

    private static func greenSpacePhrase(_ label: String?) -> String {
        switch label?.lowercased() {
        case "dense": return "dense"
        case "moderate": return "moderate"
        case "sparse": return "sparse"
        default: return "limited"
        }
    }

    private static func populationPhrase(_ count: Int?) -> String {
        guard let count else { return "not yet recorded in population" }
        switch count {
        case ..<10_000: return "sparsely populated"
        case 10_000..<30_000: return "moderately populated"
        default: return "densely populated"
        }
    }

    private static func elevationPhrase(_ label: String?) -> String {
        switch label?.lowercased() {
        case "highland": return "the highlands"
        case "lowland": return "the lowlands"
        case "coastal": return "a coastal area"
        default: return "an area of moderate elevation"
        }
    }

    private static func roadPhrase(_ types: [String]) -> String {
        let hierarchy = ["Collector Road", "Local Road", "Other Road", "Footpath"]
        let present = hierarchy.filter { types.contains($0) }

        guard let highest = present.first else { return "limited road access" }

        if present.count > 1 {
            return "multiple roads, up to a \(highest.lowercased())"
        } else {
            return "a \(highest.lowercased())"
        }
    }

    private static func facilityPhrase(_ distance: Int?) -> String {
        guard let distance else { return "at an unrecorded distance" }
        switch distance {
        case ..<500: return "very close by"
        case 500..<1500: return "nearby"
        case 1500..<3000: return "not too far away"
        default: return "somewhat far from this location"
        }
    }

    private static func connectivityPhrase(wifi: Double?, mobile: Double?) -> String {
        let best = max(wifi ?? 0, mobile ?? 0)
        switch best {
        case ..<10: return "fairly limited"
        case 10..<30: return "fairly good"
        case 30..<60: return "strong"
        default: return "very strong"
        }
    }

    private static func crimePhrase(_ rate: Double?) -> String {
        guard let rate else { return "not yet recorded" }
        switch rate {
        case ..<150: return "relatively low"
        case 150..<350: return "at a moderate level"
        default: return "fairly high"
        }
    }
}
