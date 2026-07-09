//
//  PlaceDetailView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import MapKit
import Translation

struct PlaceDetailView: View {
    let place: PlaceResult
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: PlaceDetailViewModel
    @StateObject private var weather = WeatherManager()
    @EnvironmentObject private var settings : SettingsViewModel

    init(place: PlaceResult, previewVM: PlaceDetailViewModel? = nil) {
        self.place = place
        _vm = StateObject(wrappedValue: previewVM ?? PlaceDetailViewModel(place: place))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                headerSection

                actionAndWeatherRow

                miniMap

                overviewSection

                if vm.isFetchingIntel {
                    Center { ProgressView(L.t(.analyzingArea, settings.selectedLanguage)).padding() }
                } else if let intel = vm.intel {
                    detailsSection(intel: intel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.background).ignoresSafeArea())
        .translationTask(vm.translationConfig) { session in
            await vm.processTranslation(session: session)
        }
        .task {
            weather.loadIfNeeded(for: place.coordinate)
            await vm.loadDataAndSummarize()
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            Task { await vm.regenerateSummary() }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(Theme.Typography.title)
                    .foregroundColor(Color(.textPrimary))

                Text(place.subtitle)
                    .font(Theme.Typography.subtitle)
                    .foregroundColor(Color(.textSecondary))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(.textPrimary))
                    .frame(width: 44, height: 44)
                    .background(Color(.cardBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.top,30)
    }

    private var actionAndWeatherRow: some View {
        HStack(spacing: 11) {
            Button(action: openInMaps) {
                HStack(spacing: 6) {
                    Text(L.t(.openInMaps, settings.selectedLanguage))
                        .font(Theme.Typography.description)
                    Image(systemName: "map")
                        .font(Theme.Typography.description)
                }
                .foregroundColor(.white)
                .frame(width: 118, height: 33)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }

            if weather.isLoading {
                HStack() {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 75, height: 36)
                    }
                }
            } else {
                WeatherChip(icon: weather.snapshot?.weatherSymbol ?? "-", label: weather.snapshot?.temperature ?? "—")
                WeatherChip(icon: "humidity", label: weather.snapshot?.humidity ?? "-")
                WeatherChip(icon: uvIcon(for: weather.snapshot?.uv ?? "—"), label: weather.snapshot?.uv ?? "—")
            }
        }
        .padding(.vertical, 4)
    }

    private func uvIcon(for uvLabel: String) -> String {
        let value = uvLabel.components(separatedBy: " ").first.flatMap { Int($0) } ?? 0
        switch value {
        case 0...2: return "sun.min"
        case 3...5: return "sun.max"
        case 6...7: return "sun.max.trianglebadge.exclamationmark"
        default:    return "sun.max.trianglebadge.exclamationmark.fill"
        }
    }

    private var miniMap: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )) {
            Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                CustomPinMarker()
            }
        }
        .allowsHitTesting(false)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var overviewSection: some View {
        let lang = settings.selectedLanguage
        return VStack(alignment: .leading, spacing: 8) {
            Text(L.t(.overview, lang))
                .font(Theme.Typography.option)
                .foregroundColor(Color(.textPrimary))

            let displayText = vm.translatedOverview ?? vm.aiOverview ?? L.t(.analyzingParams, lang)

            Text(displayText)
                .font(Theme.Typography.subtitle)
                .foregroundColor(Color(.textSecondary))
                .lineSpacing(4)

            if vm.isSummarizing && (vm.aiOverview ?? "").isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(L.t(.summarizing, lang))
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(Color(.brand))
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Dynamic Details Section

    private func detailsSection(intel: PlaceIntel) -> some View {
        let lang = settings.selectedLanguage
        return VStack(alignment: .leading, spacing: 24) {
            Text(L.t(.details, lang))
                .font(Theme.Typography.title)
                .foregroundColor(Color(.textPrimary))

            let envCards = generateEnvironmentCards(intel: intel)
            if !envCards.isEmpty { renderCategory(title: L.t(.secEnvironment, lang), cards: envCards) }

            let accCards = generateAccessibilityCards(intel: intel)
            if !accCards.isEmpty { Divider(); renderCategory(title: L.t(.secAccessibilities, lang), cards: accCards) }

            let socialCards = generateSocialCards(intel: intel)
            if !socialCards.isEmpty { Divider(); renderCategory(title: L.t(.secSocial, lang), cards: socialCards) }

            let geoCards = generateGeographyCards(intel: intel)
            if !geoCards.isEmpty { Divider(); renderCategory(title: L.t(.secGeography, lang), cards: geoCards) }

            let netCards = generateNetworkCards(intel: intel)
            if !netCards.isEmpty { Divider(); renderCategory(title: L.t(.secNetwork, lang), cards: netCards) }
        }
    }

    private func openInMaps() {
        let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = place.name
        item.openInMaps()
    }

    // MARK: - Render Helpers

    private func renderCategory(title: String, cards: [CardData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.Typography.section)
                .foregroundColor(Color(.textPrimary))

            let paired = pairCards(cards)

            VStack(spacing: 0) {
                ForEach(Array(paired.enumerated()), id: \.offset) { _, row in
                    if row.right?.isTall == true {
                        tallRow(leftCards: row.leftGroup, rightCard: row.right!)
                    } else {
                        HStack(alignment: .center, spacing: 16) {
                            MetricCard(title: row.left.title, value: row.left.value, icon: row.left.icon)
                                .frame(maxWidth: .infinity)

                            if let right = row.right {
                                MetricCard(title: right.title, value: right.value, icon: right.icon)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }

    private func tallRow(leftCards: [CardData], rightCard: CardData) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ForEach(leftCards) { card in
                    MetricCard(title: card.title, value: card.value, icon: card.icon)
                }
            }
            .frame(maxWidth: .infinity)

            MetricCard(
                title: rightCard.title,
                value: rightCard.value,
                icon: rightCard.icon,
                isTall: true,
                decorativeIcon: rightCard.decorativeIcon
            )
            .frame(maxWidth: .infinity)
        }
    }

    private struct CardRow {
        let left: CardData
        let leftGroup: [CardData]
        let right: CardData?
    }

    private func pairCards(_ cards: [CardData]) -> [CardRow] {
        var rows: [CardRow] = []
        var i = 0

        while i < cards.count {
            let current = cards[i]

            if i + 1 < cards.count && cards[i + 1].isTall {
                let tallCard = cards[i + 1]

                var leftGroup: [CardData] = [current]
                var j = i + 2
                while j < cards.count && !cards[j].isTall {
                    if leftGroup.count < 2 {
                        leftGroup.append(cards[j])
                        j += 1
                    } else {
                        break
                    }
                }

                rows.append(CardRow(left: current, leftGroup: leftGroup, right: tallCard))
                i = j
            } else {
                let right = i + 1 < cards.count ? cards[i + 1] : nil
                rows.append(CardRow(left: current, leftGroup: [current], right: right))
                i += 2
            }
        }

        return rows
    }

    private func generateEnvironmentCards(intel: PlaceIntel) -> [CardData] {
        let lang = settings.selectedLanguage
        var cards: [CardData] = []
        if settings.showTemperature {
            cards.append(CardData(title: L.t(.temperature, lang), value: L.value(intel.temperatureLevel, lang), icon: "thermometer.medium"))
        }
        if settings.showFloodRisk {
            cards.append(CardData(title: L.t(.floodRisk, lang), value: L.value(intel.floodRisk, lang), icon: "water.waves", isTall: true, decorativeIcon: "water.waves"))
        }
        if settings.showAirQuality {
            cards.append(CardData(title: L.t(.airQuality, lang), value: L.value(intel.airQualityLevel, lang), icon: "wind"))
        }
        return cards
    }

    private func generateAccessibilityCards(intel: PlaceIntel) -> [CardData] {
        let lang = settings.selectedLanguage
        var cards: [CardData] = []
        if settings.showGreenSpaces {
            cards.append(CardData(title: L.t(.greenSpaces, lang), value: L.value(intel.greenSpaces, lang), icon: "tree"))
        }
        if settings.showRoadAccess {
            cards.append(CardData(title: L.t(.roadAccess, lang), value: L.value(intel.roadAccess, lang), icon: "road.lanes", isTall: true, decorativeIcon: "road.lanes"))
        }
        if settings.showPublicFacilities {
            let fac = L.t(.cardPubFacilities, lang)
            if intel.hasSchool   { cards.append(CardData(title: fac, value: L.value("School", lang), icon: "building.2")) }
            if intel.hasHospital { cards.append(CardData(title: fac, value: L.value("Hospital", lang), icon: "cross.case")) }
            if intel.hasPolice   { cards.append(CardData(title: fac, value: L.value("Police", lang), icon: "building.columns")) }
            if !intel.hasSchool && !intel.hasHospital && !intel.hasPolice {
                cards.append(CardData(title: fac, value: L.value("None nearby", lang), icon: "building.slash"))
            }
        }
        return cards
    }

    private func generateSocialCards(intel: PlaceIntel) -> [CardData] {
        let lang = settings.selectedLanguage
        var cards: [CardData] = []
        if settings.showPopulation, let pop = intel.population {
            cards.append(CardData(title: L.t(.population, lang), value: pop.formatted(.number.grouping(.automatic)), icon: "person.2"))
        }
        if settings.showCrimeData, let crime = intel.crimeTotal {
            cards.append(CardData(title: L.t(.cardCrimeCase, lang), value: "\(crime) \(L.t(.perYear, lang))", icon: "exclamationmark.shield", isTall: true, decorativeIcon: "exclamationmark.shield"))
        }
        if settings.showFamilies, let fam = intel.families {
            cards.append(CardData(title: L.t(.families, lang), value: fam.formatted(.number.grouping(.automatic)), icon: "figure.2.and.child.holdinghands"))
        }
        return cards
    }

    private func generateGeographyCards(intel: PlaceIntel) -> [CardData] {
        let lang = settings.selectedLanguage
        var cards: [CardData] = []
        if settings.showElevation {
            cards.append(CardData(title: L.t(.elevation, lang), value: L.value(intel.elevationLevel, lang), icon: "mountain.2"))
        }
        return cards
    }

    private func generateNetworkCards(intel: PlaceIntel) -> [CardData] {
        let lang = settings.selectedLanguage
        var cards: [CardData] = []
        guard settings.showNetworkData else { return cards }
        if let wDl = intel.wifiDownload    { cards.append(CardData(title: L.t(.cardWifiDownload, lang), value: "\(wDl) Mbps", icon: "")) }
        if let wUl = intel.wifiUpload      { cards.append(CardData(title: L.t(.cardWifiUpload, lang), value: "\(wUl) Mbps", icon: "")) }
        if let mDl = intel.mobileDownload  { cards.append(CardData(title: L.t(.cardCellularDownload, lang), value: "\(mDl) Mbps", icon: "")) }
        if let mUl = intel.mobileUpload    { cards.append(CardData(title: L.t(.cardCellularUpload, lang), value: "\(mUl) Mbps", icon: "")) }
        return cards
    }

    // MARK: - Helper Components & Structures

    struct CardData: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        var isTall: Bool = false
        var decorativeIcon: String? = nil
    }

    struct Center<Content: View>: View {
        @ViewBuilder var content: Content
        var body: some View {
            HStack {
                Spacer()
                content
                Spacer()
            }
        }
    }

    #Preview("Place Detail — Hi-Fi") {
        let previewVM = PlaceDetailViewModel.preview()

        return Color.gray.opacity(0.3)
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                PlaceDetailView(place: previewVM.place, previewVM: previewVM)
                    .environmentObject(SettingsViewModel())
                    .presentationDetents([.height(420), .large])
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            }
    }
}
