//
//  OverviewAI.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@MainActor
enum OverviewAI {
    enum Outcome {
        case direct(String)
        case needsTranslation(String)
    }

    static func prewarm() {
        guard case .available = SystemLanguageModel.default.availability else { return }
        LanguageModelSession(model: .default).prewarm(promptPrefix: nil)
    }

    static func summarize(
        locationName: String,
        intel: PlaceIntel,
        preferIndonesian: Bool,
        onPartial: @escaping (String) -> Void
    ) async -> Outcome {
        guard case .available = SystemLanguageModel.default.availability else {
            print("[OverviewAI] Apple Intelligence unavailable — pakai template \(preferIndonesian ? "ID" : "EN").")
            return .direct(PlaceOverviewComposer.summary(locationName: locationName, for: intel, indonesian: preferIndonesian))        }

        do {
            let english = try await generateEnglish(locationName: locationName, intel: intel, onPartial: onPartial)
            let trimmed = english.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return .direct(PlaceOverviewComposer.summary(locationName: locationName, for: intel, indonesian: preferIndonesian))            }
            return preferIndonesian ? .needsTranslation(english) : .direct(english)
        } catch {
            print("[OverviewAI] Generate error: \(error.localizedDescription) — fallback template.")
            return .direct(PlaceOverviewComposer.summary(locationName: locationName, for: intel, indonesian: preferIndonesian))        }
    }

    private static func generateEnglish(
        locationName: String,
        intel: PlaceIntel,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        let session = LanguageModelSession(
            model: .default,
            instructions: """
            You are a property-location analyst. Summarize the given area parameters \
            into ONE short natural paragraph (max 70 words) for home buyers. \
            Plain prose only — no lists, no headings, and absolutely NO markdown symbols (do not use **). \
            Write in English.
            """
        )
        var latest = ""
        for try await snapshot in session.streamResponse(to: promptText(locationName: locationName, intel: intel)) {
            latest = snapshot.content
            onPartial(latest)
        }
        return latest
    }

    private static func promptText(locationName: String, intel: PlaceIntel) -> String {
        let popText   = intel.population    != nil ? "\(intel.population!) people" : "Unknown"
        let crimeText = intel.crimeTotal    != nil ? "\(intel.crimeTotal!) criminal cases reported" : "Unknown"
        let wifiText  = intel.wifiDownload  != nil ? "\(intel.wifiDownload!) Mbps DL" : "Unknown"
        let cellText  = intel.mobileDownload != nil ? "\(intel.mobileDownload!) Mbps DL" : "Unknown"

        return """
        Location Name: \(locationName) (Start your summary using this exact name, do NOT use "This area")
        Context: a residential area in Indonesia
        Temperature: \(intel.temperatureLevel)
        Flood risk: \(intel.floodRisk)
        Air quality: \(intel.airQualityLevel)
        Elevation: \(intel.elevationLevel)
        Green space: \(intel.greenSpaces)
        Road access: \(intel.roadAccess)
        Public facilities nearby: \(intel.facilityCount)
        Population: \(popText)
        Crime Data: \(crimeText)
        WiFi Network Speed: \(wifiText)
        Cellular Network Speed: \(cellText)
        """
    }
}
#endif
