//
//  PlaceDetailViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

//
//  PlaceDetailViewModel.swift
//  CH4-ProPerty
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

    // Bahasa Overview MENGIKUTI setting app ini — bukan bahasa device.
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    let place: PlaceResult
    var prefersIndonesian: Bool { appLanguage == "id" }

    init(place: PlaceResult) { self.place = place }

    func loadDataAndSummarize() async {
        isFetchingIntel = true
        errorMessage = nil
        do {
            let fetched = try await PlaceIntelService.fetchIntel(lat: place.latitude, lng: place.longitude)
            intel = fetched
            isFetchingIntel = false
            await generateSummary(using: fetched)
        } catch {
            isFetchingIntel = false
            errorMessage = error.localizedDescription
            print("API Fetch Failed: \(error.localizedDescription)")
            let mock = PlaceIntel.mock(for: place.coordinate)
            intel = mock
            await generateSummary(using: mock)
        }
    }

    /// Buat ulang ringkasan memakai intel yang sudah ada — dipanggil saat bahasa app diganti.
    func regenerateSummary() async {
        guard let intel else { return }
        translatedOverview = nil
        aiOverview = nil
        await generateSummary(using: intel)
    }

    private func generateSummary(using intelData: PlaceIntel) async {
        isSummarizing = true
        defer { isSummarizing = false }

        let wantIndonesian = prefersIndonesian   // sumber kebenaran: setting app

        if #available(iOS 26.0, *) {
            let outcome = await OverviewAI.summarize(
                intel: intelData,
                preferIndonesian: wantIndonesian
            ) { [weak self] partial in
                // Untuk ID, jangan tampilkan streaming English — tunggu hasil terjemahan penuh.
                guard let self, !wantIndonesian else { return }
                self.aiOverview = partial
            }

            switch outcome {
            case .direct(let text):
                translatedOverview = nil
                aiOverview = text
            case .needsTranslation(let english):
                aiOverview = english
                startTranslation()          // EN→ID via Apple Translation; gagal → template ID
            }
        } else {
            // iOS < 26: tanpa Apple Intelligence → template deterministik sesuai bahasa app.
            translatedOverview = nil
            aiOverview = PlaceOverviewComposer.summary(for: intelData, indonesian: wantIndonesian)
        }
    }

    func startTranslation() {
        isTranslating = true
        if translationConfig == nil {
            translationConfig = .init(source: .init(identifier: "en"),
                                      target: .init(identifier: "id"))
        } else {
            translationConfig?.invalidate()
        }
    }

    func processTranslation(session: TranslationSession) async {
        guard let source = aiOverview else { isTranslating = false; return }
        do {
            let response = try await session.translate(source)
            let text = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
            // Terjemahan kosong → template Indonesia.
            translatedOverview = text.isEmpty
                ? intel.map { PlaceOverviewComposer.summary(for: $0, indonesian: true) }
                : text
        } catch {
            // Apple Translation gagal / paket bahasa tak ada → template Indonesia deterministik,
            // bukan dibiarkan tampil English.
            translatedOverview = intel.map { PlaceOverviewComposer.summary(for: $0, indonesian: true) }
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
