import SwiftUI
import MapKit
import Translation

// MARK: - Layar peta utama

struct MainMapView: View {
    @StateObject private var location = LocationManager()
    @StateObject private var weather = WeatherModel()

    private static let bali = CLLocationCoordinate2D(latitude: -8.65, longitude: 115.16)

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MainMapView.bali,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    )
    @State private var mapCenter = MainMapView.bali
    @State private var useHybrid = false

    @State private var showSearch = false
    @State private var pinned: PlaceResult?
    @State private var detail: PlaceResult?
    @State private var bookmarks: Set<String> = []

    var body: some View {
        MapReader { proxy in
        Map(position: $camera) {
            UserAnnotation()
            if let pinned {
                Marker(pinned.name, coordinate: pinned.coordinate)
                    .tint(Theme.pin)
            }
        }
        .mapStyle(useHybrid ? .hybrid : .standard)
        .onMapCameraChange(frequency: .onEnd) { context in
            mapCenter = context.region.center
            weather.loadIfNeeded(for: context.region.center)
        }
        .task {
            weather.loadIfNeeded(for: mapCenter)
            // Panaskan model AI sejak awal biar ringkasan pertama tidak lambat.
            if #available(iOS 26.0, *) {
                OverviewAI.prewarm()
            }
        }
        .onTapGesture { screenPoint in
            guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
            handleMapTap(at: coordinate)
        }
        .safeAreaInset(edge: .top) { header }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .onChange(of: location.lastLocation?.latitude) { _, _ in
            guard let coordinate = location.lastLocation else { return }
            camera = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet(center: mapCenter, bookmarks: $bookmarks) { place in
                select(place)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $detail) { place in
            PlaceDetailView(place: place)
                .presentationDetents([.height(360), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(360)))
        }
        }
    }

    // MARK: Header (logo + chip cuaca mock)

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("Pro").foregroundColor(Theme.primary) + Text("Perty").foregroundColor(.black))
                .font(.system(size: 20, weight: .heavy, design: .rounded))
            HStack(spacing: 8) {
                weatherChip("sun.max.fill", weather.snapshot?.temperature ?? "—", .orange)
                weatherChip("drop.fill", weather.snapshot?.precipitation ?? "—", .blue)
                weatherChip("humidity.fill", weather.snapshot?.humidity ?? "—", .teal)
                weatherChip("sun.min.fill", weather.snapshot?.uv ?? "—", .yellow)
                if weather.isLoading {
                    ProgressView().controlSize(.small)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func weatherChip(_ icon: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color)
            Text(label).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.95), in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    // MARK: Bar bawah (search + locate)

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button {
                useHybrid.toggle()
            } label: {
                Image(systemName: "map.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(.black.opacity(0.85), in: Circle())
            }

            Button {
                showSearch = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    Text("Search a location").foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "mic.fill").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Button {
                location.requestLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(Theme.primary, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Aksi

    /// Ketuk peta → reverse geocode → pin + detail langsung muncul.
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        Task {
            let origin = location.lastLocation ?? mapCenter
            guard let place = await ReverseGeocodeService.place(at: coordinate, from: origin) else { return }
            pinned = place
            detail = place
        }
    }

    private func select(_ place: PlaceResult) {
        showSearch = false
        pinned = place
        camera = .region(
            MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
        // Beri jeda supaya sheet pencarian tertutup dulu.
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            detail = place
        }
    }
}

// MARK: - Sheet pencarian

struct SearchSheet: View {
    let center: CLLocationCoordinate2D
    @Binding var bookmarks: Set<String>
    let onSelect: (PlaceResult) -> Void

    @State private var query = ""
    @State private var results: [PlaceResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isFieldFocused: Bool
    @StateObject private var completer = SearchCompleter()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search a location", text: $query)
                    .focused($isFieldFocused)
                    .submitLabel(.search)
                    .onSubmit(runSearch)
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "mic.fill").foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(.secondarySystemBackground), in: Capsule())
            .padding(16)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
            }

            if results.isEmpty {
                // Saran autocomplete ala Apple Maps (banyak pilihan saat mengetik).
                List(completer.suggestions, id: \.self) { suggestion in
                    Button {
                        runSearch(completion: suggestion)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            } else {
                List(results) { place in
                    SearchResultRow(
                        place: place,
                        isBookmarked: bookmarks.contains(place.name),
                        onBookmark: { toggleBookmark(place) },
                        onTap: { onSelect(place) }
                    )
                    .listRowSeparator(.visible)
                }
                .listStyle(.plain)
            }
        }
        .onAppear { isFieldFocused = true }
        .onChange(of: query) { _, newQuery in
            results = []
            completer.update(query: newQuery, around: center)
        }
    }

    private func runSearch(completion: MKLocalSearchCompletion) {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let found = try await PlaceSearchService.search(completion: completion, around: center)
                results = found
                if found.isEmpty {
                    errorMessage = String(
                        format: NSLocalizedString("No results for \"%@\".", comment: ""),
                        completion.title
                    )
                }
            } catch {
                errorMessage = String(
                    format: NSLocalizedString("Search failed: %@", comment: ""),
                    error.localizedDescription
                )
            }
        }
    }

    private func runSearch() {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let found = try await PlaceSearchService.search(query: query, around: center)
                results = found
                if found.isEmpty {
                    errorMessage = String(
                        format: NSLocalizedString("No results for \"%@\".", comment: ""),
                        query
                    )
                }
            } catch {
                errorMessage = String(
                    format: NSLocalizedString("Search failed: %@", comment: ""),
                    error.localizedDescription
                )
            }
        }
    }

    private func toggleBookmark(_ place: PlaceResult) {
        if bookmarks.contains(place.name) {
            bookmarks.remove(place.name)
        } else {
            bookmarks.insert(place.name)
        }
    }
}

struct SearchResultRow: View {
    let place: PlaceResult
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 3) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.pin)
                if let distance = place.distanceLabel {
                    Text(distance)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(place.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text(place.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(Theme.primary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.vertical, 4)
    }
}

// MARK: - Detail tempat

struct PlaceDetailView: View {
    let place: PlaceResult
    @Environment(\.dismiss) private var dismiss

    @State private var aiOverview: String?
    @State private var translatedOverview: String?
    @State private var isSummarizing = false
    @State private var isTranslating = false
    @State private var translationConfig: TranslationSession.Configuration?

    // Sekali jalur "minta Indonesia langsung" gagal di device ini, langsung
    // pakai jalur EN + translate di run berikutnya (hindari generate dua kali).
    @AppStorage("directIndonesianFailed") private var directIndonesianFailed = false

    private var intel: PlaceIntel { .mock(for: place.coordinate) }
    private var prefersIndonesian: Bool {
        Locale.current.language.languageCode?.identifier == "id"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name)
                            .font(.title2.weight(.bold))
                        Text(place.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.primary)
                            .padding(9)
                            .background(Color(.secondarySystemBackground), in: Circle())
                    }
                }

                Button(action: openInMaps) {
                    HStack(spacing: 6) {
                        Text("Open in maps")
                        Image(systemName: "map")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.primary, in: RoundedRectangle(cornerRadius: 8))
                }

                miniMap

                section("Overview") {
                    // Teks tampil sambil di-stream (aiOverview terisi progresif).
                    Text(translatedOverview ?? aiOverview ?? (isSummarizing ? "" : intel.overview))
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                    if isSummarizing && (aiOverview ?? "").isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Summarizing with Apple Intelligence…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if isTranslating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Translating…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !isSummarizing && !isTranslating && (translatedOverview ?? aiOverview) != nil {
                        Label("Summarized on-device by Apple Intelligence", systemImage: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(Theme.primary)
                    }
                }

                Text("Details")
                    .font(.headline)

                section("Environment") {
                    metricGrid([
                        ("Temperature", intel.temperatureLevel, "thermometer.medium"),
                        ("Flood Risk", intel.floodRisk, "water.waves"),
                        ("Air Quality", intel.airQualityLevel, "wind")
                    ])
                }

                section("Accessibilities") {
                    metricGrid([
                        ("Green Spaces", intel.greenSpaces, "leaf.fill"),
                        ("Road Access", intel.roadAccess, "road.lanes"),
                        ("Pub. Facilities", "School", "building.2.fill"),
                        ("Pub. Facilities", "Hospital", "cross.case.fill")
                    ])
                }

                Text("Environment data above is still mocked (prototype).")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
        }
        .presentationDragIndicator(.visible)
        .translationTask(translationConfig) { session in
            guard let source = aiOverview else {
                isTranslating = false
                return
            }
            do {
                let response = try await session.translate(source)
                translatedOverview = response.targetText
            } catch {
                // Gagal translate → tampilkan teks Inggris apa adanya.
                translatedOverview = nil
            }
            isTranslating = false
        }
        .task {
            guard #available(iOS 26.0, *) else { return }
            isSummarizing = true
            let outcome = await OverviewAI.summarize(
                placeName: place.name,
                subtitle: place.subtitle,
                intel: intel,
                preferIndonesian: prefersIndonesian,
                allowDirectIndonesian: !directIndonesianFailed
            ) { partial in
                aiOverview = partial   // streaming: paragraf tampil sambil jadi
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
                aiOverview = nil   // fallback: template lokal ter-lokalisasi
            }
        }
    }

    /// Pemicu translate yang bisa diulang — assign config bernilai sama tidak
    /// me-retrigger .translationTask, harus invalidate().
    private func startTranslation() {
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

    private var miniMap: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        )) {
            Marker(place.name, coordinate: place.coordinate)
                .tint(Theme.pin)
        }
        .allowsHitTesting(false)
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            content()
        }
    }

    private func metricGrid(_ items: [(String, String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(item.0))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey(item.1))
                            .font(.subheadline.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: item.2)
                        .foregroundStyle(Theme.primary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.primary)
                        .frame(width: 3, height: 34)
                }
            }
        }
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        item.name = place.name
        item.openInMaps()
    }
}

#Preview {
    MainMapView()
}
