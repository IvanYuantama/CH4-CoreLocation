//
//  PlaceIntelService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation

enum PlaceIntelService {
    
    private static let roadRank: [String: Int] = [
        "Arterial": 5, "Collector": 4, "Local": 3, "Other": 2, "Footpath": 1
    ]

    private static func dominantRoad(from labels: [String]) -> String? {
        guard !labels.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for l in labels { counts[l, default: 0] += 1 }
        return counts.max { a, b in
            if a.value != b.value { return a.value < b.value }
            let ra = roadRank[a.key] ?? 0, rb = roadRank[b.key] ?? 0
            if ra != rb { return ra < rb }
            return a.key > b.key
        }?.key
    }
    
    static func fetchIntel(lat: Double, lng: Double) async throws -> PlaceIntel {
            let urlString = "https://api.ryansafa.cloud/api/analyze?lat=\(lat)&lng=\(lng)"
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ [PlaceIntelService] Server Error! Status Code: \(httpResponse.statusCode)")
                throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataArray = json["data"] as? [[String: Any]] else {
                throw URLError(.cannotParseResponse)
            }
            
            var intel = PlaceIntel()
            var facilitiesCount = 0
            var roadLabels: [String] = []
            
            for item in dataArray {
                let layer = item["layer"] as? String ?? ""
                let label = item["label"] as? String ?? ""
                let distance = item["distance_meters"] as? Double ?? 0
                let attributes = item["attributes"] as? [String: Any] ?? [:]
                
                switch layer {
                case "temperature":
                    intel.temperatureLevel = label
                    
                case "flood":
                    intel.floodRisk = label.replacingOccurrences(of: " Flood Risk", with: "")
                    
                case "air_quality":
                    intel.airQualityLevel = label
                    
                case "green_spaces":
                    intel.greenSpaces = label
                    
                case "elevation":
                    intel.elevationLevel = label
                    
                case "population":
                    if let pop = attributes["jumlah_pen"] as? Double { intel.population = Int(pop) }
                    else if let pop = attributes["jumlah_pen"] as? Int { intel.population = pop }
                    
                    if let fam = attributes["jumlah_kk"] as? Double { intel.families = Int(fam) }
                    else if let fam = attributes["jumlah_kk"] as? Int { intel.families = fam }
                    
                case "roads_buffer":
                    if distance == 0 {
                        let roadName = label.replacingOccurrences(of: " Road", with: "")
                        if !roadName.isEmpty {roadLabels.append(roadName)}
                    }
                    
                case "public_facilities":
                    let totalInCategory = item["total"] as? Int ?? 1
                    facilitiesCount += totalInCategory
                    
                    let cat = (attributes["kategori"] as? String ?? label).lowercased()
                    if cat.contains("pendidikan") { intel.hasSchool = true }
                    if cat.contains("kesehatan") { intel.hasHospital = true }
                    if cat.contains("keamanan") || cat.contains("polisi") { intel.hasPolice = true }
                    
                case "crime":
                    intel.crimeLevel = label
                    if let total = attributes["crime_total"] as? Int {
                        intel.crimeTotal = total
                    }
                    
                case "wifi":
                    if let dl = attributes["dl_mbps"] as? Double { intel.wifiDownload = dl }
                    if let ul = attributes["ul_mbps"] as? Double { intel.wifiUpload = ul }
                    
                case "mobile_data":
                    if let dl = attributes["dl_mbps"] as? Double { intel.mobileDownload = dl }
                    if let ul = attributes["ul_mbps"] as? Double { intel.mobileUpload = ul }
                    
                default:
                    break
                }
            }
            
            if let dominant = Self.dominantRoad(from: roadLabels){
                intel.roadAccess = dominant
            }
            
            intel.facilityCount = facilitiesCount
            return intel
        }
}
