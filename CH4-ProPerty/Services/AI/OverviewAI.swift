//
//  OverviewAI.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

//  Rangkum parameter lokasi jadi satu paragraf via Apple Intelligence (on-device).
//  Hanya tersedia di iOS 26+ dengan Apple Intelligence aktif.
//  Fallback ke PlaceIntel.overview jika tidak tersedia.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
enum OverviewAI {

    /// Generate ringkasan overview lokasi dalam 1 paragraf (max 70 kata).
    /// Return nil jika Apple Intelligence tidak tersedia di device.
    static func summarize(
        placeName: String,
        subtitle: String,
        intel: PlaceIntel
    ) async -> String? {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return nil }

        // Otomatis Bahasa Indonesia jika language setting device adalah "id"
        let isIndonesian = Locale.current.language.languageCode?.identifier == "id"
        let outputLanguage = isIndonesian ? "Bahasa Indonesia" : "English"

        let session = LanguageModelSession(instructions: """
            You are a property-location analyst. Summarize the given area parameters \
            into ONE short natural paragraph (max 70 words) for home buyers. \
            Plain prose only — no lists, no headings, no markdown. \
            Write the paragraph in \(outputLanguage).
            """)

        let prompt = """
            Area: \(placeName), \(subtitle)
            Average temperature: \(String(format: "%.1f", intel.avgTemp))°C (level: \(intel.temperatureLevel))
            Flood risk: \(intel.floodRisk)
            Air quality: \(intel.airQualityLevel) (AQI \(intel.aqi))
            Water quality: \(intel.waterQuality)/100
            Elevation: \(intel.elevation) m above sea level
            Crime rate: \(intel.crimeLevel)
            Green space: \(intel.greenPercent)% (\(intel.greenSpaces))
            Road access: \(intel.roadAccess)
            Public facilities within 2 km: \(intel.facilityCount)
            """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}
