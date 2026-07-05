//
//  PlaceIntel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

import CoreLocation

struct PlaceIntel {
    let avgTemp: Double
    let temperatureLevel: String
    let floodRisk: String
    let airQualityLevel: String
    let aqi: Int
    let waterQuality: Int
    let elevation: Int
    let crimeLevel: String
    let greenPercent: Int
    let greenSpaces: String
    let roadAccess: String
    let facilityCount: Int

    // MARK: - Init dari backend response

    init(from response: PointAnalysisResponse) {
        func value(for layer: String) -> LayerResult? {
            response.data.first { $0.layer == layer }
        }
        self.avgTemp          = 27.0
        self.temperatureLevel = value(for: "temperature")?.label ?? "Unknown"
        self.floodRisk        = value(for: "flood")?.label       ?? "Unknown"
        self.airQualityLevel  = value(for: "air_quality")?.label ?? "Unknown"
        self.aqi              = 0
        self.waterQuality     = 0
        // FIX: elevation dari label backend, bukan Int — simpan 0 sebagai default
        self.elevation        = 0
        self.crimeLevel       = "Low"
        self.greenPercent     = 0
        self.greenSpaces      = value(for: "green_spaces")?.label  ?? "Unknown"
        self.roadAccess       = value(for: "roads_buffer")?.label  ?? "Unknown"
        self.facilityCount    = 0
    }

    // MARK: - Overview fallback

    var overview: String {
        "This area has \(floodRisk.lowercased()) flood risk, \(airQualityLevel.lowercased()) air quality, " +
        "\(greenSpaces.lowercased()) green spaces, and \(roadAccess.lowercased()) road access."
    }

    // MARK: - Mock untuk Preview

    static func mock(for coordinate: CLLocationCoordinate2D) -> PlaceIntel {
        var seed = UInt64(bitPattern: Int64((coordinate.latitude * 10_000).rounded()))
            &+ UInt64(bitPattern: Int64((coordinate.longitude * 10_000).rounded())) &* 31

        func roll(_ range: ClosedRange<Int>) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return range.lowerBound + Int(seed >> 33) % range.count
        }

        let levels = ["Low", "Medium", "High"]
        return PlaceIntel(
            avgTemp:          24 + Double(roll(0...60)) / 10.0,
            temperatureLevel: levels[roll(0...2)],
            floodRisk:        levels[roll(0...2)],
            airQualityLevel:  levels[roll(0...2)],
            aqi:              roll(40...160),
            waterQuality:     roll(55...90),
            elevation:        roll(3...120),
            crimeLevel:       ["Low", "Medium"][roll(0...1)],
            greenPercent:     roll(15...60),
            greenSpaces:      ["Sparse", "Moderate", "Dense"][roll(0...2)],
            roadAccess:       ["Local", "Collector", "Arterial"][roll(0...2)],
            facilityCount:    roll(8...40)
        )
    }

    private init(
        avgTemp: Double, temperatureLevel: String, floodRisk: String,
        airQualityLevel: String, aqi: Int, waterQuality: Int, elevation: Int,
        crimeLevel: String, greenPercent: Int, greenSpaces: String,
        roadAccess: String, facilityCount: Int
    ) {
        self.avgTemp          = avgTemp
        self.temperatureLevel = temperatureLevel
        self.floodRisk        = floodRisk
        self.airQualityLevel  = airQualityLevel
        self.aqi              = aqi
        self.waterQuality     = waterQuality
        self.elevation        = elevation
        self.crimeLevel       = crimeLevel
        self.greenPercent     = greenPercent
        self.greenSpaces      = greenSpaces
        self.roadAccess       = roadAccess
        self.facilityCount    = facilityCount
    }
}
