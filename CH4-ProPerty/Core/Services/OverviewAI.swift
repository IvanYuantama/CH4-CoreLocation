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
        case unavailable
    }

    static func prewarm() {
        guard case .available = SystemLanguageModel.default.availability else { return }
        LanguageModelSession(model: .default).prewarm(promptPrefix: nil)
    }

    static func summarize(
        placeName: String,
        subtitle: String,
        intel: PlaceIntel,
        preferIndonesian: Bool,
        allowDirectIndonesian: Bool,
        onPartial: @escaping (String) -> Void
    ) async -> Outcome {
        guard case .available = SystemLanguageModel.default.availability else {
            print("[OverviewAI] Model tidak tersedia di device ini.")
            return .unavailable
        }

        let prompt = promptText(intel: intel)

        if preferIndonesian && allowDirectIndonesian {
            if let direct = try? await generate(prompt: prompt, inIndonesian: true, onPartial: onPartial),
               !direct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .direct(direct)
            }
        }

        do {
            let english = try await generate(prompt: prompt, inIndonesian: false, onPartial: onPartial)
            guard !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .unavailable }
            return preferIndonesian ? .needsTranslation(english) : .direct(english)
        } catch {
            // 🌟 Menambahkan print agar kamu bisa melihat error dari Apple Intelligence di Xcode
            print("[OverviewAI] Generate Error: \(error.localizedDescription)")
            return .unavailable
        }
    }

    private static func generate(prompt: String, inIndonesian: Bool, onPartial: @escaping (String) -> Void) async throws -> String {
        let languageLine = inIndonesian ? "Write the paragraph in Bahasa Indonesia." : "Write the paragraph in English."
        let session = LanguageModelSession(
            model: .default,
            instructions: """
            You are a property-location analyst. Summarize the given area parameters \
            into ONE short natural paragraph (max 70 words) for home buyers. \
            Plain prose only — no lists, no headings, no markdown. \
            \(languageLine)
            """
        )
        var latest = ""
        let stream = session.streamResponse(to: prompt)
        for try await snapshot in stream {
            latest = snapshot.content
            onPartial(latest)
        }
        return latest
    }

    // 🌟 Menghapus parameter placeName dan subtitle agar tidak memicu error bahasa
    private static func promptText(intel: PlaceIntel) -> String {
        let popText = intel.population != nil ? "\(intel.population!) people" : "Unknown"
        let crimeText = intel.crimeTotal != nil ? "\(intel.crimeTotal!) criminal cases reported" : "Unknown"
        let wifiText = (intel.wifiDownload != nil) ? "\(intel.wifiDownload!) Mbps DL" : "Unknown"
        let cellText = (intel.mobileDownload != nil) ? "\(intel.mobileDownload!) Mbps DL" : "Unknown"
            
        return """
        Area: a residential area in Indonesia (refer to it as "this area")
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
