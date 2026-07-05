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
        guard case .available = SystemLanguageModel.default.availability else { return .unavailable }

        let prompt = promptText(placeName: placeName, subtitle: subtitle, intel: intel)

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

    private static func promptText(placeName: String, subtitle: String, intel: PlaceIntel) -> String {
            let popText = intel.population != nil ? "\(intel.population!) people" : "Unknown"
            
            return """
            Area: \(placeName), \(subtitle)
            Temperature: \(intel.temperatureLevel)
            Flood risk: \(intel.floodRisk)
            Air quality: \(intel.airQualityLevel)
            Elevation: \(intel.elevationLevel)
            Green space: \(intel.greenSpaces)
            Road access: \(intel.roadAccess)
            Public facilities nearby: \(intel.facilityCount)
            Population: \(popText)
            """
        }
}
#endif
