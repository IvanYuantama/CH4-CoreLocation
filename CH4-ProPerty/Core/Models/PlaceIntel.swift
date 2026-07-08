//
//  PlaceIntel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
import CoreLocation

struct PlaceIntel {
    var temperatureLevel: String = "Unknown"
    var floodRisk: String = "Unknown"
    var airQualityLevel: String = "Unknown"
    var greenSpaces: String = "Unknown"
    var roadAccess: String = "Unknown"
    var population: Int? = nil
    var families: Int? = nil
    var elevationLevel: String = "Unknown"
    var crimeLevel: String = "Unknown"
    var crimeTotal: Int? = nil
    var crimeClearanceRate: Double? = nil
    var wifiDownload: Double? = nil
    var wifiUpload: Double? = nil
    var mobileDownload: Double? = nil
    var mobileUpload: Double? = nil
    var hasSchool: Bool = false
    var hasHospital: Bool = false
    var hasPolice: Bool = false
    var facilityCount: Int = 0
    
    var isSample: Bool = false
}

extension PlaceIntel {
    static func mock(for coordinate: CLLocationCoordinate2D) -> PlaceIntel {
        return PlaceIntel(
            temperatureLevel: "Cool",
            floodRisk: "Low",
            airQualityLevel: "Good",
            greenSpaces: "Dense",
            roadAccess: "Collector",
            population: 55352,
            families: 16798,
            elevationLevel: "Highland",
            crimeLevel: "Low",
            
            crimeTotal: 1027,
            crimeClearanceRate: 79.85,
            wifiDownload: 68.9,
            wifiUpload: 52.7,
            mobileDownload: 30.9,
            mobileUpload: 14.2,
            
            hasSchool: true,
            hasHospital: true,
            hasPolice: true,
            facilityCount: 28,
            
            isSample: true
        )
    }
}
