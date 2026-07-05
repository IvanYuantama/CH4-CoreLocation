//
//  PlaceIntelService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation

enum PlaceIntelService {
    static func fetchIntel(lat: Double, lng: Double) async throws -> PlaceIntel {
        let urlString = "https://api.ryansafa.cloud/api/analyze?lat=\(lat)&lng=\(lng)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Menggunakan JSONSerialization karena struktur "attributes" sangat dinamis per layer
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        var intel = PlaceIntel()
        var facilitiesCount = 0
        
        for item in dataArray {
            let layer = item["layer"] as? String ?? ""
            let label = item["label"] as? String ?? ""
            let distance = item["distance_meters"] as? Double ?? 0
            let attributes = item["attributes"] as? [String: Any] ?? [:]
            
            switch layer {
            case "temperature":
                intel.temperatureLevel = label
            case "flood":
                // Menghilangkan kata " Flood Risk" agar UI lebih bersih (misal: "Low Flood Risk" jadi "Low")
                intel.floodRisk = label.replacingOccurrences(of: " Flood Risk", with: "")
            case "air_quality":
                intel.airQualityLevel = label
            case "green_spaces":
                intel.greenSpaces = label
            case "elevation":
                intel.elevationLevel = label
            case "population":
                if let pop = attributes["jumlah_pen"] as? Int { intel.population = pop }
                if let fam = attributes["jumlah_kk"] as? Int { intel.families = fam }
            case "roads_buffer":
                // Mengambil jalan yang posisinya paling dekat dengan pin (distance 0)
                if distance == 0 {
                    intel.roadAccess = label.replacingOccurrences(of: " Road", with: "")
                }
            case "public_facilities":
                facilitiesCount += 1
                let cat = (attributes["kategori"] as? String ?? label).lowercased()
                if cat.contains("pendidikan") { intel.hasSchool = true }
                if cat.contains("kesehatan") { intel.hasHospital = true }
                if cat.contains("keamanan") { intel.hasPolice = true }
            case "crime":
                intel.crimeLevel = label
            default:
                break
            }
        }
        
        intel.facilityCount = facilitiesCount
        return intel
    }
}
