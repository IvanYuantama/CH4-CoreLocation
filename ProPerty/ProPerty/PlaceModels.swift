import Foundation
import CoreLocation
import MapKit
import WeatherKit
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Hasil pencarian lokasi

struct PlaceResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var distanceLabel: String? {
        guard let distanceKm else { return nil }
        return distanceKm < 10
            ? String(format: "%.1f km", distanceKm)
            : "\(Int(distanceKm.rounded())) km"
    }

    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool { lhs.id == rhs.id }
}

// MARK: - Pencarian (MKLocalSearch)

enum PlaceSearchService {
    static func search(query: String, around center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        return try await run(request: request, around: center)
    }

    /// Pencarian dari saran autocomplete (MKLocalSearchCompleter).
    static func search(completion: MKLocalSearchCompletion, around center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        try await run(request: MKLocalSearch.Request(completion: completion), around: center)
    }

    private static func run(request: MKLocalSearch.Request, around center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        let response = try await MKLocalSearch(request: request).start()
        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return response.mapItems.map { item in
            let placemark = item.placemark
            let coordinate = placemark.coordinate
            let distanceMeters = origin.distance(
                from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
            let subtitleParts = [
                placemark.subAdministrativeArea,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }
            var seen = Set<String>()
            let subtitle = subtitleParts.filter { seen.insert($0).inserted }.joined(separator: ", ")

            return PlaceResult(
                name: item.name ?? AppLanguage.string("Unnamed"),
                subtitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                distanceKm: distanceMeters / 1000
            )
        }
    }
}

// MARK: - Intel wilayah (MOCK — data sintetis untuk prototype)

/// Nilai deterministik dari koordinat, jadi tempat yang sama selalu
/// menghasilkan angka yang sama. BUKAN data asli.
struct PlaceIntel {
    let avgTemp: Double
    let temperatureLevel: String
    let floodRisk: String
    let airQualityLevel: String
    let aqi: Int
    let waterQuality: Int
    let elevation: Int
    let crimeLevel: String
    let greenPercent: Int
    let greenSpaces: String
    let roadAccess: String
    let facilityCount: Int

    /// Paragraf fallback (non-AI), ter-lokalisasi lewat template di Localizable.xcstrings.
    var overview: String {
        func localized(_ key: String) -> String { AppLanguage.string(key) }
        return String(
            format: AppLanguage.string("overview_template"),
            String(facilityCount),
            String(waterQuality),
            localized(airQualityLevel).lowercased(),
            String(aqi),
            String(elevation),
            String(format: "%.1f", avgTemp),
            localized(crimeLevel).lowercased(),
            String(greenPercent)
        )
    }

    static func mock(for coordinate: CLLocationCoordinate2D) -> PlaceIntel {
        var seed = UInt64(bitPattern: Int64((coordinate.latitude * 10_000).rounded()))
            &+ UInt64(bitPattern: Int64((coordinate.longitude * 10_000).rounded())) &* 31

        func roll(_ range: ClosedRange<Int>) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return range.lowerBound + Int(seed >> 33) % range.count
        }

        let levels = ["Low", "Medium", "High"]
        let aqi = roll(40...160)

        return PlaceIntel(
            avgTemp: 24 + Double(roll(0...60)) / 10.0,
            temperatureLevel: levels[roll(0...2)],
            floodRisk: levels[roll(0...2)],
            airQualityLevel: levels[roll(0...2)],
            aqi: aqi,
            waterQuality: roll(55...90),
            elevation: roll(3...120),
            crimeLevel: ["Low", "Medium"][roll(0...1)],
            greenPercent: roll(15...60),
            greenSpaces: ["Sparse", "Moderate", "Dense"][roll(0...2)],
            roadAccess: ["Local", "Collector", "Arterial"][roll(0...2)],
            facilityCount: roll(8...40)
        )
    }
}

// MARK: - Lokasi live

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            errorMessage = AppLanguage.string("Location permission denied. Enable it in Settings.")
        default:
            manager.startUpdatingLocation()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.lastLocation = coordinate
            manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = String(
                format: AppLanguage.string("Failed to get location: %@"),
                error.localizedDescription
            )
        }
    }
}

// MARK: - Cuaca real (WeatherKit)

@MainActor
final class WeatherModel: ObservableObject {
    struct Snapshot {
        let temperature: String
        let precipitation: String
        let humidity: String
        let uv: String
    }

    @Published var snapshot: Snapshot?
    @Published var isLoading = false

    private var lastFetchLocation: CLLocation?

    /// Ambil cuaca untuk area peta. Skip kalau geser < 25 km dari fetch terakhir
    /// supaya hemat kuota (500k call/bulan gratis).
    func loadIfNeeded(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let lastFetchLocation,
           snapshot != nil,
           lastFetchLocation.distance(from: location) < 25_000 {
            return
        }
        lastFetchLocation = location
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                let current = weather.currentWeather
                let tempC = Int(current.temperature.converted(to: .celsius).value.rounded())
                let humidity = Int((current.humidity * 100).rounded())
                let precipMM = weather.hourlyForecast.forecast.first?
                    .precipitationAmount.converted(to: .millimeters).value ?? 0
                snapshot = Snapshot(
                    temperature: "\(tempC)°C",
                    precipitation: String(format: "%.0f mm", precipMM),
                    humidity: "\(humidity)%",
                    uv: "\(current.uvIndex.value) UV"
                )
            } catch {
                // Gagal (mis. capability belum aktif) → chip menampilkan "—".
            }
        }
    }
}

// MARK: - Autocomplete saran ketikan (ala Apple Maps)

@MainActor
final class SearchCompleter: NSObject, ObservableObject {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    func update(query: String, around center: CLLocationCoordinate2D) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
        completer.queryFragment = trimmed
    }
}

extension SearchCompleter: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in self.suggestions = results }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.suggestions = [] }
    }
}

// MARK: - Reverse geocoding (ketuk peta → detail tempat)

enum ReverseGeocodeService {
    /// Koordinat → PlaceResult (nama + alamat) via CLGeocoder.
    static func place(
        at coordinate: CLLocationCoordinate2D,
        from origin: CLLocationCoordinate2D
    ) async -> PlaceResult? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(
            location,
            preferredLocale: Locale(identifier: "id_ID")
        ).first else { return nil }

        let name = placemark.name
            ?? placemark.subLocality
            ?? placemark.locality
            ?? AppLanguage.string("Selected location")
        let subtitleParts = [
            placemark.subLocality,
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }
        var seen = Set<String>()
        let subtitle = subtitleParts.filter { seen.insert($0).inserted }.joined(separator: ", ")

        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let distanceKm = originLocation.distance(from: location) / 1000

        return PlaceResult(
            name: name,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            distanceKm: distanceKm
        )
    }
}

// MARK: - Ringkasan Overview via Apple Foundation Models (on-device, iOS 26+)

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@MainActor
enum OverviewAI {
    /// Hasil ringkasan:
    /// - direct: sudah dalam bahasa app, langsung tampil
    /// - needsTranslation: Inggris — caller menerjemahkan EN→ID via Translation framework
    /// - unavailable: model tak tersedia / gagal total → pakai template lokal
    enum Outcome {
        case direct(String)
        case needsTranslation(String)
        case unavailable(String?)   // alasan gagal, untuk diagnostik UI
    }

    /// Muat model ke memori lebih awal supaya request pertama tidak lambat.
    static func prewarm() {
        guard case .available = SystemLanguageModel.default.availability else { return }
        LanguageModelSession(model: .default).prewarm(promptPrefix: nil)
    }

    /// Alasan model tidak tersedia (untuk ditampilkan sebagai diagnostik).
    /// Nil kalau model tersedia.
    static func availabilityNote() -> String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "Device ini tidak mendukung Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence belum aktif. Nyalakan di Settings → Apple Intelligence & Siri. Catatan: bahasa SISTEM harus bahasa yang didukung (mis. English) — kalau bahasa sistem Indonesia, Apple Intelligence mati otomatis."
        case .unavailable(.modelNotReady):
            return "Model AI sedang diunduh / belum siap. Coba lagi beberapa menit."
        case .unavailable(let other):
            return "Model AI tidak tersedia: \(String(describing: other))"
        }
    }

    /// Rangkum parameter wilayah. Teks parsial dikirim lewat onPartial (streaming),
    /// jadi UI bisa menampilkan paragraf sambil di-generate.
    static func summarize(
        placeName: String,
        subtitle: String,
        intel: PlaceIntel,
        preferIndonesian: Bool,
        allowDirectIndonesian: Bool,
        onPartial: @escaping (String) -> Void
    ) async -> Outcome {
        guard case .available = SystemLanguageModel.default.availability else {
            return .unavailable(availabilityNote())
        }

        print("[OverviewAI] start\n\(debugDump())")
        let prompt = promptText(placeName: placeName, subtitle: subtitle, intel: intel)
        print("[OverviewAI] prompt:\n\(prompt)")

        // Jalur 1: minta Bahasa Indonesia langsung (best-effort — id belum resmi didukung).
        if preferIndonesian && allowDirectIndonesian {
            if let direct = try? await generate(prompt: prompt, inIndonesian: true, onPartial: onPartial),
               !direct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .direct(direct)
            }
        }

        // Jalur 2: Inggris (bahasa terkuat model); diterjemahkan caller bila perlu.
        do {
            let english = try await generate(prompt: prompt, inIndonesian: false, onPartial: onPartial)
            guard !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("[OverviewAI] EN generation returned EMPTY")
                return .unavailable("Model mengembalikan teks kosong.")
            }
            print("[OverviewAI] EN generation OK (\(english.count) chars)")
            return preferIndonesian ? .needsTranslation(english) : .direct(english)
        } catch {
            print("[OverviewAI] EN generation FAILED: \(error)")
            if error is TimeoutError {
                // Streaming macet — coba sekali lewat jalur non-streaming.
                print("[OverviewAI] mencoba fallback non-streaming respond()")
                if let fallback = try? await respondOnce(prompt: prompt, inIndonesian: false),
                   !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("[OverviewAI] respond() OK (\(fallback.count) chars)")
                    onPartial(fallback)
                    return preferIndonesian ? .needsTranslation(fallback) : .direct(fallback)
                }
                return .unavailable(
                    "Model tidak merespons (streaming & non-streaming sama-sama timeout). "
                    + "Kemungkinan daemon Apple Intelligence macet: restart iPhone, "
                    + "lalu cek Settings → Apple Intelligence & Siri — pastikan tidak ada model yang masih download."
                )
            }
            var reason = describe(error)
            if let generationError = error as? LanguageModelSession.GenerationError,
               case .unsupportedLanguageOrLocale = generationError {
                // Probe: bedakan "SEMUA request ditolak" (locale app) vs
                // "cuma prompt kita yang ditolak" (konten, mis. nama tempat).
                let probeSucceeded = await probeEnglish()
                print("[OverviewAI] plain-English probe = \(probeSucceeded)")
                reason += probeSucceeded
                    ? "\n→ Probe Inggris polos BERHASIL: yang ditolak konten prompt (kemungkinan nama tempat)."
                    : "\n→ Probe Inggris polos juga DITOLAK: locale app masih tidak didukung — cek Settings → Apps → ProPerty → Language harus English/default."
                reason += "\nlocale=\(Locale.current.identifier)"
            }
            return .unavailable(reason)
        }
    }

    /// Prompt Inggris paling polos — kalau ini pun ditolak, masalahnya locale, bukan konten.
    private static func probeEnglish() async -> Bool {
        let session = LanguageModelSession(
            model: .default,
            instructions: "You reply with a single English word."
        )
        let result = try? await session.respond(to: "Reply with the word: hello")
        return !(result?.content.isEmpty ?? true)
    }

    /// Info locale + bahasa yang didukung model, untuk console Xcode.
    private static func debugDump() -> String {
        let supported = SystemLanguageModel.default.supportedLanguages
            .map { "\($0.languageCode?.identifier ?? "?")\($0.region.map { "-\($0.identifier)" } ?? "")" }
            .sorted()
            .joined(separator: ", ")
        return """
        Locale.current = \(Locale.current.identifier)
        preferredLanguages = \(Locale.preferredLanguages.joined(separator: ", "))
        model.supportedLanguages = [\(supported)]
        """
    }

    /// Terjemahkan error FoundationModels jadi pesan diagnostik yang bisa dibaca.
    private static func describe(_ error: Error) -> String {
        if error is TimeoutError {
            return "Model tidak merespons dalam \(generationTimeoutSeconds) detik (timeout). "
                + "Coba tutup-buka kartu; kalau berulang, restart app / device."
        }
        guard let generationError = error as? LanguageModelSession.GenerationError else {
            return "Generate gagal: \(error.localizedDescription)"
        }
        switch generationError {
        case .guardrailViolation:
            return "Kena guardrail keamanan konten Apple — sebagian isi prompt dianggap sensitif."
        case .exceededContextWindowSize:
            return "Prompt melebihi kapasitas konteks model."
        case .unsupportedLanguageOrLocale:
            return "Bahasa/locale prompt tidak didukung model."
        case .assetsUnavailable:
            return "Aset model belum tersedia di device."
        case .rateLimited:
            return "Terlalu banyak request — kena rate limit, coba lagi."
        case .concurrentRequests:
            return "Masih ada request lain yang berjalan."
        case .refusal:
            return "Model menolak merangkum konten ini."
        default:
            return "Generate gagal: \(generationError.localizedDescription)"
        }
    }

    // MARK: - Private

    /// Batas tunggu generate — stream Foundation Models kadang macet
    /// sebelum snapshot pertama; tanpa batas ini UI loading selamanya.
    /// (Token pertama normalnya < 5 detik; 30 detik sudah sangat longgar.)
    private static let generationTimeoutSeconds = 30

    struct TimeoutError: Error {}

    private static func makeSession(inIndonesian: Bool) -> LanguageModelSession {
        let languageLine = inIndonesian
            ? "Write the paragraph in Bahasa Indonesia."
            : "Write the paragraph in English."
        return LanguageModelSession(
            model: .default,
            instructions: """
            You are a property-location analyst. Summarize the given area parameters \
            into ONE short natural paragraph (max 70 words) for home buyers. \
            Plain prose only — no lists, no headings, no markdown. \
            \(languageLine)
            """
        )
    }

    /// Jalur cadangan non-streaming — dipakai saat jalur streaming timeout.
    private static func respondOnce(prompt: String, inIndonesian: Bool) async throws -> String {
        let session = makeSession(inIndonesian: inIndonesian)
        let request = Task { @MainActor () throws -> String in
            try await session.respond(to: prompt).content
        }
        let watchdog = Task { @MainActor in
            try? await Task.sleep(for: .seconds(generationTimeoutSeconds))
            print("[OverviewAI] WATCHDOG: respond() \(generationTimeoutSeconds)s tanpa hasil — cancel")
            request.cancel()
        }
        defer { watchdog.cancel() }
        do {
            return try await request.value
        } catch is CancellationError {
            throw TimeoutError()
        }
    }

    private static func generate(
        prompt: String,
        inIndonesian: Bool,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        let session = makeSession(inIndonesian: inIndonesian)

        let generation = Task { @MainActor () throws -> String in
            var latest = ""
            var snapshots = 0
            print("[OverviewAI] stream begin (indonesian=\(inIndonesian))")
            let stream = session.streamResponse(to: prompt)
            for try await snapshot in stream {
                snapshots += 1
                if snapshots == 1 { print("[OverviewAI] first snapshot received") }
                latest = snapshot.content
                onPartial(latest)
            }
            print("[OverviewAI] stream done: \(snapshots) snapshots, \(latest.count) chars")
            // Stream yang di-cancel watchdog bisa berakhir "sukses" dengan 0
            // snapshot — pastikan itu dilaporkan sebagai timeout, bukan kosong.
            try Task.checkCancellation()
            return latest
        }
        let watchdog = Task { @MainActor in
            try? await Task.sleep(for: .seconds(generationTimeoutSeconds))
            print("[OverviewAI] WATCHDOG: \(generationTimeoutSeconds)s tanpa hasil — cancel stream")
            generation.cancel()
        }
        defer { watchdog.cancel() }
        do {
            return try await generation.value
        } catch is CancellationError {
            throw TimeoutError()
        }
    }

    /// PENTING: prompt TIDAK boleh memuat nama tempat/subtitle Indonesia —
    /// detektor bahasa model membaca "Kecamatan/Kabupaten/…" sebagai bahasa id
    /// dan menolak seluruh request ("Unsupported language id detected").
    /// Nama tempat sudah tampil di header UI, jadi cukup "this area" di prompt.
    private static func promptText(placeName: String, subtitle: String, intel: PlaceIntel) -> String {
        """
        Area: a residential area in Indonesia (refer to it as "this area")
        Average temperature: \(String(format: "%.1f", intel.avgTemp))°C (level: \(intel.temperatureLevel))
        Flood risk: \(intel.floodRisk)
        Air quality: \(intel.airQualityLevel) (AQI \(intel.aqi))
        Water quality: \(intel.waterQuality)/100
        Elevation: \(intel.elevation) m above sea level
        Neighborhood safety: \(intel.crimeLevel == "Low" ? "generally safe" : "moderately safe")
        Green space: \(intel.greenPercent)% (\(intel.greenSpaces))
        Road access: \(intel.roadAccess)
        Public facilities within 2 km: \(intel.facilityCount)
        """
    }
}
#endif
