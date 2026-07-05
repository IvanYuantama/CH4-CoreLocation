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
    @StateObject private var settings = SettingsViewModel()
    
    init(place: PlaceResult) {
        self.place = place
        _vm = StateObject(wrappedValue: PlaceDetailViewModel(place: place))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Drag Indicator Tiruan
                Center {
                    Capsule()
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                }
                
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
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.textPrimary)
                
                Text(place.subtitle)
                    .font(Theme.Typography.category)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(Theme.cardBackground)
                    .clipShape(Circle())
            }
        }
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
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                }
                
                if weather.isLoading {
                    ProgressView().padding(.horizontal)
                } else if let snap = weather.snapshot {
                    WeatherChip(icon: "thermometer.sun", label: snap.temperature)
                    WeatherChip(icon: "drop", label: snap.humidity)
                    WeatherChip(icon: "sun.max", label: snap.uv)
                }
            }
            .padding(.vertical, 4)
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
                .foregroundColor(Theme.textPrimary)
            
            let displayText = vm.translatedOverview ?? vm.aiOverview ?? "Analyzing property environment parameters..."
            
            Text(displayText)
                .font(Theme.Typography.category)
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(4)
            
            if vm.isSummarizing && (vm.aiOverview ?? "").isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Summarizing with Apple Intelligence...")
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(Theme.primary)
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
                .foregroundColor(Theme.textPrimary)
            
            // 1. Environment Category
            let envCards = generateEnvironmentCards(intel: intel)
            if !envCards.isEmpty {
                renderCategory(title: "Environment", cards: envCards)
            }
            
            // 2. Accessibilities Category
            let accCards = generateAccessibilityCards(intel: intel)
            if !accCards.isEmpty {
                Divider()
                renderCategory(title: "Accessibilities", cards: accCards)
            }
            
            // 3. Social Category
            let socialCards = generateSocialCards(intel: intel)
            if !socialCards.isEmpty {
                Divider()
                renderCategory(title: "Social", cards: socialCards)
            }
            
            // 4. Geography Category
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
                .foregroundColor(Theme.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Generate kartu selang-seling berdasarkan indeks
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    MetricCard(
                        title: card.title,
                        value: card.value,
                        icon: card.icon,
                        isReversed: index % 2 != 0 // True jika indeks ganjil (kolom kanan)
                    )
                }
            }
        }
    }
    
    private func generateEnvironmentCards(intel: PlaceIntel) -> [CardData] {
        var cards: [CardData] = []
        if settings.showTemperature { cards.append(CardData(title: "Temperature", value: intel.temperatureLevel, icon: "thermometer.medium")) }
        if settings.showFloodRisk { cards.append(CardData(title: "Flood Risk", value: intel.floodRisk, icon: "water.waves")) }
        if settings.showAirQuality { cards.append(CardData(title: "Air Quality", value: intel.airQualityLevel, icon: "wind")) }
        return cards
    }
    
    private func generateAccessibilityCards(intel: PlaceIntel) -> [CardData] {
            var cards: [CardData] = []
            if settings.showGreenSpaces { cards.append(CardData(title: "Green Spaces", value: intel.greenSpaces, icon: "tree")) }
            if settings.showRoadAccess { cards.append(CardData(title: "Road Access", value: intel.roadAccess, icon: "road.lanes")) }
            
            if settings.showPublicFacilities {
                // Dinamis berdasarkan API
                if intel.hasSchool { cards.append(CardData(title: "Pub. Facilities", value: "School", icon: "building.2")) }
                if intel.hasHospital { cards.append(CardData(title: "Pub. Facilities", value: "Hospital", icon: "cross.case")) }
                if intel.hasPolice { cards.append(CardData(title: "Pub. Facilities", value: "Police", icon: "building.columns")) }
                
                // Jika fasilitas nol, kita tampilkan info kosong
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

#Preview("Place Detail") {
    PlaceDetailView(place: PlaceResult(
        name: "Canggu",
        subtitle: "Kabupaten Badung, Bali, Indonesia",
        latitude: -8.6478,
        longitude: 115.1385,
        distanceKm: 2.5
    ))
}
