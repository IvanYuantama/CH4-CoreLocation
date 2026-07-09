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
        case direct(String)           // teks final siap tampil dalam bahasa target
        case needsTranslation(String) // teks English AI yang perlu diterjemah ke ID
    }

    static func prewarm() {
        guard case .available = SystemLanguageModel.default.availability else { return }
        LanguageModelSession(model: .default).prewarm(promptPrefix: nil)
    }

    /// Bahasa hasil ditentukan `preferIndonesian` (dari setting APP) — BUKAN bahasa device.
    static func summarize(
        intel: PlaceIntel,
        preferIndonesian: Bool,
        onPartial: @escaping (String) -> Void
    ) async -> Outcome {
        // Apple Intelligence tak tersedia (device tak dukung / AI dimatikan / bahasa device
        // tak didukung) → template deterministik dalam bahasa APP.
        guard case .available = SystemLanguageModel.default.availability else {
            print("[OverviewAI] Apple Intelligence unavailable — pakai template \(preferIndonesian ? "ID" : "EN").")
            return .direct(PlaceOverviewComposer.summary(for: intel, indonesian: preferIndonesian))
        }

        do {
            // Selalu generate English lebih dulu (paling andal untuk model on-device,
            // apa pun bahasa device).
            let english = try await generateEnglish(intel: intel, onPartial: onPartial)
            let trimmed = english.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return .direct(PlaceOverviewComposer.summary(for: intel, indonesian: preferIndonesian))
            }
            // EN → tampil langsung; ID → minta ViewModel menerjemahkan via Apple Translation.
            return preferIndonesian ? .needsTranslation(english) : .direct(english)
        } catch {
            print("[OverviewAI] Generate error: \(error.localizedDescription) — fallback template.")
            return .direct(PlaceOverviewComposer.summary(for: intel, indonesian: preferIndonesian))
        }
    }

    private static func generateEnglish(
        intel: PlaceIntel,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        let session = LanguageModelSession(
            model: .default,
            instructions: """
            You are a property-location analyst. Summarize the given area parameters \
            into ONE short natural paragraph (max 70 words) for home buyers. \
            Plain prose only — no lists, no headings, no markdown. Write in English.
            """
        )
        var latest = ""
        for try await snapshot in session.streamResponse(to: promptText(intel: intel)) {
            latest = snapshot.content
            onPartial(latest)
        }
        return latest
    }

    private static func promptText(intel: PlaceIntel) -> String {
        let popText   = intel.population    != nil ? "\(intel.population!) people" : "Unknown"
        let crimeText = intel.crimeTotal    != nil ? "\(intel.crimeTotal!) criminal cases reported" : "Unknown"
        let wifiText  = intel.wifiDownload  != nil ? "\(intel.wifiDownload!) Mbps DL" : "Unknown"
        let cellText  = intel.mobileDownload != nil ? "\(intel.mobileDownload!) Mbps DL" : "Unknown"

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
