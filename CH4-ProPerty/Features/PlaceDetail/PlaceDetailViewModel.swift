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
    
    // State untuk data API ryansafa.cloud
    @Published var intel: PlaceIntel?
    @Published var isFetchingIntel = false
    @Published var errorMessage: String?
    
    @AppStorage("directIndonesianFailed") var directIndonesianFailed = false
    
    let place: PlaceResult
    var prefersIndonesian: Bool { Locale.current.language.languageCode?.identifier == "id" }
    
    init(place: PlaceResult) {
        self.place = place
    }
    
    func loadDataAndSummarize() async {
        isFetchingIntel = true
        errorMessage = nil
        
        do {
            // 1. Fetch data riil dari backend
            let fetchedIntel = try await PlaceIntelService.fetchIntel(lat: place.latitude, lng: place.longitude)
            self.intel = fetchedIntel
            self.isFetchingIntel = false
            
            // 2. Generate summary menggunakan data riil
            await generateSummary(using: fetchedIntel)
            
        } catch {
            self.isFetchingIntel = false
            self.errorMessage = error.localizedDescription
            print("API Fetch Failed: \(error.localizedDescription)")
            
            // Fallback ke mock data sementara jika API sedang down, agar UI tetap bisa di-test
            let mockIntel = PlaceIntel.mock(for: place.coordinate)
            self.intel = mockIntel
            await generateSummary(using: mockIntel)
        }
    }
    
    private func generateSummary(using intelData: PlaceIntel) async {
        guard #available(iOS 26.0, *) else { return }
        isSummarizing = true
        
        let outcome = await OverviewAI.summarize(
            placeName: place.name,
            subtitle: place.subtitle,
            intel: intelData,
            preferIndonesian: prefersIndonesian,
            allowDirectIndonesian: !directIndonesianFailed
        ) { partial in
            self.aiOverview = partial
        }
        
        isSummarizing = false
        
        switch outcome {
        case .direct(let text):
            aiOverview = text
            if prefersIndonesian { directIndonesianFailed = false }
        case .needsTranslation(let text):
            directIndonesianFailed = true
            aiOverview = text
            startTranslation()
        case .unavailable:
            aiOverview = nil
        }
    }
    
    func startTranslation() {
        isTranslating = true
        if translationConfig == nil {
            translationConfig = .init(
                source: .init(identifier: "en"),
                target: .init(identifier: "id")
            )
        } else {
            translationConfig?.invalidate()
        }
    }
    
    func processTranslation(session: TranslationSession) async {
        guard let source = aiOverview else {
            isTranslating = false
            return
        }
        do {
            let response = try await session.translate(source)
            translatedOverview = response.targetText
        } catch {
            translatedOverview = nil
        }
        isTranslating = false
    }
}
