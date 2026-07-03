//
//  LayerKey.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

//  Enum untuk 8 layer spasial yang tersedia di backend PostGIS.
//  Nilai rawValue sesuai persis dengan :layerKey di endpoint
//  GET /api/layers/:layerKey
//

import Foundation

enum LayerKey: String, CaseIterable, Identifiable {
    case flood            = "flood"
    case temperature      = "temperature"
    case airQuality       = "air_quality"
    case greenSpaces      = "green_spaces"
    case publicFacilities = "public_facilities"
    case population       = "population"
    case elevation        = "elevation"
    case roadsBuffer      = "roads_buffer"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flood:            return "Flood Risk"
        case .temperature:      return "Temperature"
        case .airQuality:       return "Air Quality"
        case .greenSpaces:      return "Green Spaces"
        case .publicFacilities: return "Public Facilities"
        case .population:       return "Population"
        case .elevation:        return "Elevation"
        case .roadsBuffer:      return "Road Access"
        }
    }

    var icon: String {
        switch self {
        case .flood:            return "drop.triangle.fill"
        case .temperature:      return "thermometer.sun.fill"
        case .airQuality:       return "wind"
        case .greenSpaces:      return "leaf.fill"
        case .publicFacilities: return "building.2.fill"
        case .population:       return "person.3.fill"
        case .elevation:        return "mountain.2.fill"
        case .roadsBuffer:      return "road.lanes"
        }
    }
}
