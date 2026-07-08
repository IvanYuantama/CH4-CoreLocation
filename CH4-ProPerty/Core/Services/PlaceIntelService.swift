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
        var roadTypes: Set<String> = [] // Menggunakan Set untuk mencegah duplikasi nama jalan
        
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
                // API mengirimkan format angka desimal (Double), jadi kita cast ke Double lalu ubah ke Int
                if let pop = attributes["jumlah_pen"] as? Double { intel.population = Int(pop) }
                else if let pop = attributes["jumlah_pen"] as? Int { intel.population = pop }
                
                if let fam = attributes["jumlah_kk"] as? Double { intel.families = Int(fam) }
                else if let fam = attributes["jumlah_kk"] as? Int { intel.families = fam }
                
            case "roads_buffer":
                // Mengambil jalan yang posisinya paling dekat dengan pin (distance 0)
                if distance == 0 {
                    let roadName = label.replacingOccurrences(of: " Road", with: "")
                    roadTypes.insert(roadName)
                }
                
            case "public_facilities":
                // API meletakkan "total" di luar blok attributes
                let totalInCategory = item["total"] as? Int ?? 1
                facilitiesCount += totalInCategory
                
                let cat = (attributes["kategori"] as? String ?? label).lowercased()
                if cat.contains("pendidikan") { intel.hasSchool = true }
                if cat.contains("kesehatan") { intel.hasHospital = true }
                if cat.contains("keamanan") || cat.contains("polisi") { intel.hasPolice = true }
                
            case "crime":
                intel.crimeLevel = label
                // Menangkap total kasus kriminal dari attributes
                if let total = attributes["crime_total"] as? Int {
                    intel.crimeTotal = total
                }
                
            case "wifi":
                // Menangkap kecepatan download & upload WiFi
                if let dl = attributes["dl_mbps"] as? Double { intel.wifiDownload = dl }
                if let ul = attributes["ul_mbps"] as? Double { intel.wifiUpload = ul }
                
            case "mobile_data":
                // Menangkap kecepatan download & upload Cellular/Mobile
                if let dl = attributes["dl_mbps"] as? Double { intel.mobileDownload = dl }
                if let ul = attributes["ul_mbps"] as? Double { intel.mobileUpload = ul }
                
            default:
                break
            }
        }
        
        // Gabungkan jalan jika ada tumpang tindih (contoh: "Collector, Local")
        if !roadTypes.isEmpty {
            intel.roadAccess = Array(roadTypes).joined(separator: ", ")
        }
        
        intel.facilityCount = facilitiesCount
        return intel
    }
}
