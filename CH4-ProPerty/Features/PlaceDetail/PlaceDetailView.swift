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
                    Center { ProgressView("Analyzing area...").padding() }
                } else if let intel = vm.intel {
                    detailsSection(intel: intel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Theme.background.ignoresSafeArea())
        .translationTask(vm.translationConfig) { session in
            await vm.processTranslation(session: session)
        }
        .task {
            weather.loadIfNeeded(for: place.coordinate)
            await vm.loadDataAndSummarize()
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(Theme.Typography.heading)
                    .foregroundColor(.textPrimary)
                
                Text(place.subtitle)
                    .font(Theme.Typography.category)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.top,30)
    }
    
    private var actionAndWeatherRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: openInMaps) {
                    HStack(spacing: 6) {
                        Text("Open in maps")
                        Image(systemName: "map")
                    }
                    .font(Theme.Typography.category)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.brand)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                }

                if weather.isLoading {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            Capsule()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 75, height: 36)
                        }
                    }
                } else if let snap = weather.snapshot {
                    WeatherChip(icon: snap.weatherSymbol, label: snap.temperature)
                    WeatherChip(icon: "humidity", label: snap.humidity)
                    WeatherChip(icon: uvIcon(for: snap.uv), label: snap.uv)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func uvIcon(for uvLabel: String) -> String {
        // Parse angka dari "3 UV", "8 UV", dst
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
            Marker(place.name, coordinate: place.coordinate)
                .tint(Color(red: 0.89, green: 0.22, blue: 0.21))
        }
        .allowsHitTesting(false)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(Theme.Typography.option)
                .foregroundColor(.textPrimary)
            
            let displayText = vm.translatedOverview ?? vm.aiOverview ?? "Analyzing property environment parameters..."
            
            Text(displayText)
                .font(Theme.Typography.category)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
            
            if vm.isSummarizing && (vm.aiOverview ?? "").isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Summarizing with Apple Intelligence...")
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(.brand)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Dynamic Details Section
    
    private func detailsSection(intel: PlaceIntel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Details")
                .font(Theme.Typography.title)
                .foregroundColor(.textPrimary)
            
            let envCards = generateEnvironmentCards(intel: intel)
            if !envCards.isEmpty {
                renderCategory(title: "Environment", cards: envCards)
            }
            
            let accCards = generateAccessibilityCards(intel: intel)
            if !accCards.isEmpty {
                Divider()
                renderCategory(title: "Accessibilities", cards: accCards)
            }
            
            let socialCards = generateSocialCards(intel: intel)
            if !socialCards.isEmpty {
                Divider()
                renderCategory(title: "Social", cards: socialCards)
            }
            
            let geoCards = generateGeographyCards(intel: intel)
            if !geoCards.isEmpty {
                Divider()
                renderCategory(title: "Geography", cards: geoCards)
            }
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
                .foregroundColor(.textPrimary)
            
            let paired = pairCards(cards)
            
            VStack(spacing: 0) {
                ForEach(Array(paired.enumerated()), id: \.offset) { _, row in
                    if row.right?.isTall == true {
                        tallRow(leftCards: row.leftGroup, rightCard: row.right!)
                    } else {
                        // Normal row: satu card kiri, satu card kanan
                        HStack(alignment: .center, spacing: 16) {
                            MetricCard(
                                title: row.left.title,
                                value: row.left.value,
                                icon: row.left.icon,
                                isReversed: false
                            )
                            .frame(maxWidth: .infinity)
                            
                            if let right = row.right {
                                MetricCard(
                                    title: right.title,
                                    value: right.value,
                                    icon: right.icon,
                                    isReversed: true
                                )
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
                    MetricCard(
                        title: card.title,
                        value: card.value,
                        icon: card.icon,
                        isReversed: false
                    )
                }
            }
            .frame(maxWidth: .infinity)

            MetricCard(
                title: rightCard.title,
                value: rightCard.value,
                icon: rightCard.icon,
                isReversed: true,
                isTall: true,
                decorativeIcon: rightCard.decorativeIcon
            )
            .frame(width: 140)
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
                
                rows.append(CardRow(
                    left: current,
                    leftGroup: leftGroup,
                    right: tallCard
                ))
                i = j
                
            } else {
                let right = i + 1 < cards.count ? cards[i + 1] : nil
                rows.append(CardRow(
                    left: current,
                    leftGroup: [current],
                    right: right
                ))
                i += 2
            }
        }
        
        return rows
    }
    
    private func generateEnvironmentCards(intel: PlaceIntel) -> [CardData] {
        var cards: [CardData] = []
        
        if settings.showTemperature {
            cards.append(CardData(
                title: "Temperature",
                value: intel.temperatureLevel,
                icon: "thermometer.medium"
            ))
        }
        
        if settings.showFloodRisk {
            cards.append(CardData(
                title: "Flood Risk",
                value: intel.floodRisk,
                icon: "water.waves",
                isTall: true,
                decorativeIcon: "water.waves"
            ))
        }
        
        if settings.showAirQuality {
            cards.append(CardData(
                title: "Air Quality",
                value: intel.airQualityLevel,
                icon: "wind"
            ))
        }
        
        return cards
    }
    
    private func generateAccessibilityCards(intel: PlaceIntel) -> [CardData] {
        var cards: [CardData] = []
        
        if settings.showGreenSpaces {
            cards.append(CardData(
                title: "Green Spaces",
                value: intel.greenSpaces,
                icon: "tree"
            ))
        }
        
        if settings.showRoadAccess {
            cards.append(CardData(
                title: "Road Access",
                value: intel.roadAccess,
                icon: "road.lanes",
                isTall: true,
                decorativeIcon: "road.lanes"     
            ))
        }
        
        if settings.showPublicFacilities {
            if intel.hasSchool {
                cards.append(CardData(title: "Pub. Facilities", value: "School", icon: "building.2"))
            }
            if intel.hasHospital {
                cards.append(CardData(title: "Pub. Facilities", value: "Hospital", icon: "cross.case"))
            }
            if intel.hasPolice {
                cards.append(CardData(title: "Pub. Facilities", value: "Police", icon: "building.columns"))
            }
            if !intel.hasSchool && !intel.hasHospital && !intel.hasPolice {
                cards.append(CardData(title: "Pub. Facilities", value: "None nearby", icon: "building.slash"))
            }
        }
        
        return cards
    }
    
    private func generateSocialCards(intel: PlaceIntel) -> [CardData] {
        var cards: [CardData] = []
        if settings.showPopulation, let pop = intel.population {
            let formattedPop = pop.formatted(.number.grouping(.automatic))
            cards.append(CardData(title: "Population", value: formattedPop, icon: "person.2"))
        }
        if settings.showFamilies, let fam = intel.families {
            let formattedFam = fam.formatted(.number.grouping(.automatic))
            cards.append(CardData(title: "Families", value: formattedFam, icon: "figure.2.and.child.holdinghands"))
        }
        return cards
    }
    
    private func generateGeographyCards(intel: PlaceIntel) -> [CardData] {
        var cards: [CardData] = []
        if settings.showElevation {
            cards.append(CardData(title: "Elevation", value: intel.elevationLevel, icon: "mountain.2"))
        }
        return cards
    }
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
    
    // 2. Tampilkan di dalam sheet tiruan
    return Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PlaceDetailView(
                place: previewVM.place,
                previewVM: previewVM
            )
            .environmentObject(SettingsViewModel()) 
            .presentationDetents([.height(420), .large])
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
        }
}
