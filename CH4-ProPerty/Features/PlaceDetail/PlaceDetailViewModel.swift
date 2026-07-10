//
//  PlaceDetailViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import Translation
import Combine

@MainActor
class PlaceDetailViewModel: ObservableObject {
    @Published var aiOverview: String?
    @Published var translatedOverview: String?
    @Published var isSummarizing = false
    @Published var isTranslating = false
    @Published var translationConfig: TranslationSession.Configuration?

    @Published var intel: PlaceIntel?
    @Published var isFetchingIntel = false
    @Published var errorMessage: String?
    
    @Published var isSampleData = false

    @AppStorage("appLanguage") private var appLanguage: String = "en"

    let place: PlaceResult
    var prefersIndonesian: Bool { appLanguage == "id" }
    
    private var summaryTask: Task<Void, Never>?

    init(place: PlaceResult) { self.place = place }

    func loadDataAndSummarize() async {
        isFetchingIntel = true
        errorMessage = nil
        isSampleData = false
        
        do {
            let fetched = try await PlaceIntelService.fetchIntel(lat: place.latitude, lng: place.longitude)
            intel = fetched
            isFetchingIntel = false
            await generateSummary(using: fetched)
        } catch {
            isFetchingIntel = false
            errorMessage = error.localizedDescription
            isSampleData = true
            
            print("API Fetch Failed: \(error.localizedDescription)")
            let mock = PlaceIntel.mock(for: place.coordinate)
            intel = mock
            await generateSummary(using: mock)
        }
    }

    func regenerateSummary() async {
        summaryTask?.cancel()
        
        let task = Task { @MainActor in
            guard let intel else { return }
            translatedOverview = nil
            aiOverview = nil
            await generateSummary(using: intel)
        }
        
        summaryTask = task
        await task.value
    }

    private func generateSummary(using intelData: PlaceIntel) async {
        isSummarizing = true
        defer {
            if !Task.isCancelled { isSummarizing = false }
        }

        let wantIndonesian = prefersIndonesian

        if #available(iOS 26.0, *) {
            let outcome = await OverviewAI.summarize(
                locationName: place.name,
                intel: intelData,
                preferIndonesian: wantIndonesian
            ) { [weak self] partial in
                guard let self, !wantIndonesian else { return }
                if Task.isCancelled { return }
                self.aiOverview = partial
            }
            
            if Task.isCancelled { return }

            switch outcome {
            case .direct(let text):
                translatedOverview = nil
                aiOverview = text
            case .needsTranslation(let english):
                aiOverview = english
                startTranslation()
            }
        } else {
            translatedOverview = nil
            aiOverview = PlaceOverviewComposer.summary(locationName: place.name,for: intelData, indonesian: wantIndonesian)
        }
    }

    func startTranslation() {
            isTranslating = true
            
            Task { @MainActor in
                let availability = LanguageAvailability()
                let status = await availability.status(
                    from: Locale.Language(identifier: "en"),
                    to: Locale.Language(identifier: "id")
                )
                
                if status == .installed {
                    self.translationConfig = .init(
                        source: .init(identifier: "en"),
                        target: .init(identifier: "id")
                    )
                } else {
                    print("⚠️ [Translation] Bahasa belum terunduh. Membatalkan sheet terjemahan dan menggunakan fallback template.")
                    
                    if !Task.isCancelled {
                        self.translatedOverview = self.intel.map { PlaceOverviewComposer.summary(locationName: place.name,for: $0, indonesian: true) }
                        self.isTranslating = false
                    }
                }
            }
        }
    
    private func simulateStreaming(text: String) async {
            translatedOverview = ""
            let words = text.components(separatedBy: " ")
            
            for (index, word) in words.enumerated() {
                if Task.isCancelled { break }
                
                translatedOverview?.append(word)
                if index < words.count - 1 {
                    translatedOverview?.append(" ")
                }
                
                let delay = UInt64.random(in: 30_000_000...80_000_000)
                try? await Task.sleep(nanoseconds: delay)
            }
        }

    func processTranslation(session: TranslationSession) async {
            guard let source = aiOverview else { isTranslating = false; return }
            do {
                let response = try await session.translate(source)
                if Task.isCancelled { return }
                
                let text = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalText = text.isEmpty
                    ? intel.map { PlaceOverviewComposer.summary(locationName: place.name, for: $0, indonesian: true) } ?? ""
                    : text
                
                await simulateStreaming(text: finalText)
                
            } catch {
                if !Task.isCancelled {
                    let fallbackText = intel.map { PlaceOverviewComposer.summary(locationName: place.name, for: $0, indonesian: true) } ?? ""
                    await simulateStreaming(text: fallbackText)
                }
            }
            isTranslating = false
        }
    
    static func preview() -> PlaceDetailViewModel {
        let vm = PlaceDetailViewModel(place: PlaceResult(
            name: "Canggu",
            subtitle: "Kabupaten Badung, Bali, Indonesia",
            latitude: -8.6478,
            longitude: 115.1385,
            distanceKm: 10.0
        ))
        vm.intel = PlaceIntel(
            temperatureLevel: "Low", floodRisk: "High", airQualityLevel: "Medium",
            greenSpaces: "Dense", roadAccess: "Collector",
            population: 55352, families: 16798, elevationLevel: "Lowland", crimeLevel: "Low",
            crimeTotal: 1027, crimeClearanceRate: 79.85,
            wifiDownload: 68.9, wifiUpload: 52.7, mobileDownload: 30.9, mobileUpload: 14.2,
            hasSchool: true, hasHospital: true, hasPolice: true, facilityCount: 28
        )
        vm.aiOverview = "This area offers good accessibility with major roads nearby and 28 public facilities within 2 km..."
        vm.isFetchingIntel = false
        vm.isSummarizing = false
        return vm
    }
}
