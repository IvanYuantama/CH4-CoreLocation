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
    
    @AppStorage("directIndonesianFailed") var directIndonesianFailed = false

    @AppStorage("appLanguage") private var appLanguage: String = "en"
    
    let place: PlaceResult
    
    var prefersIndonesian: Bool { appLanguage == "id" }
    
    init(place: PlaceResult) {
        self.place = place
    }
    
    func loadDataAndSummarize() async {
        isFetchingIntel = true
        errorMessage = nil
        
        do {
            let fetchedIntel = try await PlaceIntelService.fetchIntel(lat: place.latitude, lng: place.longitude)
            self.intel = fetchedIntel
            self.isFetchingIntel = false
            
            await generateSummary(using: fetchedIntel)
            
        } catch {
            self.isFetchingIntel = false
            self.errorMessage = error.localizedDescription
            print("API Fetch Failed: \(error.localizedDescription)")
            
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
    
    static func preview() -> PlaceDetailViewModel {
        let vm = PlaceDetailViewModel(place: PlaceResult(
            name: "Canggu",
            subtitle: "Kabupaten Badung, Bali, Indonesia",
            latitude: -8.6478,
            longitude: 115.1385,
            distanceKm: 10.0
        ))
        
        // Memperbarui data mock untuk preview sesuai dengan desain HiFi
        vm.intel = PlaceIntel(
            temperatureLevel: "Low",
            floodRisk: "High",
            airQualityLevel: "Medium",
            greenSpaces: "Dense",
            roadAccess: "Collector",
            population: 55352,
            families: 16798,
            elevationLevel: "Lowland",
            crimeLevel: "Low",
            
            // Properti baru
            crimeTotal: 1027,
            crimeClearanceRate: 79.85,
            wifiDownload: 68.9,
            wifiUpload: 52.7,
            mobileDownload: 30.9,
            mobileUpload: 14.2,
            
            hasSchool: true,
            hasHospital: true,
            hasPolice: true,
            facilityCount: 28
        )
        
        vm.aiOverview = "This area offers good accessibility with major roads nearby and 28 public facilities within 2 km. Water quality is moderate (72/100), while air quality is fair (AQI 118). The elevation is 35 m above sea level with an average temperature of 27.4°C. A low crime rate and 41% green space support a comfortable environment"
        vm.isFetchingIntel = false
        vm.isSummarizing = false
        return vm
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
