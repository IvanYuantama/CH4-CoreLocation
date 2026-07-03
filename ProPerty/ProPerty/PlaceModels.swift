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
                name: item.name ?? "Tanpa nama",
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

    var overview: String {
        "This area offers good accessibility with major roads nearby and \(facilityCount) "
        + "public facilities within 2 km. Water quality is moderate (\(waterQuality)/100), "
        + "while air quality is \(airQualityLevel.lowercased()) (AQI \(aqi)). The elevation is "
        + "\(elevation) m above sea level with an average temperature of "
        + String(format: "%.1f", avgTemp) + "°C. A \(crimeLevel.lowercased()) crime rate and "
        + "\(greenPercent)% green space support a comfortable environment."
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
            errorMessage = "Izin lokasi ditolak. Aktifkan di Settings."
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
            self.errorMessage = "Gagal ambil lokasi: \(error.localizedDescription)"
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
            ?? "Lokasi terpilih"
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

@available(iOS 26.0, *)
enum OverviewAI {
    /// Rangkum parameter wilayah jadi satu paragraf natural.
    /// Nil kalau model tidak tersedia (device tak didukung / Apple Intelligence off).
    static func summarize(placeName: String, subtitle: String, intel: PlaceIntel) async -> String? {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return nil }

        let session = LanguageModelSession(instructions: """
            You are a property-location analyst. Summarize the given area parameters \
            into ONE short natural English paragraph (max 70 words) for home buyers. \
            Plain prose only — no lists, no headings, no markdown.
            """)
        let prompt = """
            Area: \(placeName), \(subtitle)
            Average temperature: \(String(format: "%.1f", intel.avgTemp))°C (level: \(intel.temperatureLevel))
            Flood risk: \(intel.floodRisk)
            Air quality: \(intel.airQualityLevel) (AQI \(intel.aqi))
            Water quality: \(intel.waterQuality)/100
            Elevation: \(intel.elevation) m above sea level
            Crime rate: \(intel.crimeLevel)
            Green space: \(intel.greenPercent)% (\(intel.greenSpaces))
            Road access: \(intel.roadAccess)
            Public facilities within 2 km: \(intel.facilityCount)
            """
        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}
