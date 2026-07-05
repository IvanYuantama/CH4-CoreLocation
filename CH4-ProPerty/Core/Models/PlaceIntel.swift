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
    
    // Fasilitas Publik Dinamis
    var hasSchool: Bool = false
    var hasHospital: Bool = false
    var hasPolice: Bool = false
    var facilityCount: Int = 0
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
            hasSchool: true,
            hasHospital: true,
            hasPolice: false,
            facilityCount: 28
        )
    }
}
