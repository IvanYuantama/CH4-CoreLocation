import Foundation
import CoreLocation
import WeatherKit

// MARK: - Konfigurasi backend

enum BackendConfig {
    /// URL server property-backend (repo CH4-CoreLocation, `npm start` → port 3000).
    /// Saat run di device fisik, ganti ke IP LAN Mac (mis. http://192.168.1.10:3000)
    /// atau URL deploy. Kalau tidak terjangkau, app fallback ke SampleAnalyze.json.
    static let baseURL = URL(string: "http://192.168.110.52:3000")!  // IP LAN Mac (server `node src/index.js`)
    static let requestTimeout: TimeInterval = 8
}

// MARK: - Model response /api/analyze

struct AnalyzeResponse: Decodable {
    let success: Bool
    let data: [LayerResult]
}

struct LayerResult: Decodable {
    let layer: String
    let distanceMeters: Int?
    let label: String
    let total: Int?
    let attributes: Attributes?

    enum CodingKeys: String, CodingKey {
        case layer, label, total, attributes
        case distanceMeters = "distance_meters"
    }

    /// Hanya field yang dipakai UI (lihat README backend); sisanya diabaikan.
    struct Attributes: Decodable {
        let area: String?
        let suhu: String?
        let polusi: String?
        let rth: String?
        let ketinggian: String?
        let jumlahPen: Double?
        let namaKec: String?
        let namaKab: String?
        let dlMbps: Double?
        let ulMbps: Double?
        let crimeTotal: Double?

        enum CodingKeys: String, CodingKey {
            case area, suhu, polusi, rth, ketinggian
            case jumlahPen = "jumlah_pen"
            case namaKec = "nama_kec"
            case namaKab = "nama_kab"
            case dlMbps = "dl_mbps"
            case ulMbps = "ul_mbps"
            case crimeTotal = "crime_total"
        }
    }
}

// MARK: - Intel hasil resolve (backend + AQI + suhu realtime)

/// Kategori fasilitas umum dalam radius 1 km + jarak terdekatnya.
struct FacilityInfo: Identifiable {
    let category: String
    let count: Int
    let distanceM: Int
    var id: String { category }
}

/// "320 m" / "1,4 km"
func formatMeters(_ meters: Int) -> String {
    meters < 1000 ? "\(meters) m" : String(format: "%.1f km", Double(meters) / 1000)
}

struct PropertyIntel {
    let floodRisk: String        // flood.label
    let temperatureZone: String  // temperature.label
    let airQuality: String       // air_quality.label
    let aqi: Int?                // Open-Meteo US AQI (real)
    let elevation: String        // elevation.label
    let population: Int?         // population.attributes.jumlah_pen
    let district: String?        // nama_kec, nama_kab

    // RTH: semua zona dalam 500 m → kelas dominan (modus; seri → lebih hijau menang).
    let greenDominant: String    // Dense / Moderate / Sparse / Unknown
    let greenZoneCount: Int      // jumlah zona RTH ≤ 500 m

    // Jalan utama (Collector/Arterial) terdekat dari titik.
    let mainRoad: String?
    let mainRoadDistanceM: Int?

    let facilities: [FacilityInfo]  // kategori dalam 1 km, jarak terdekat per kategori
    let wifi: String?               // "68,9 / 52,8 Mbps"
    let wifiDistanceM: Int?         // >0 = data dari zona terdekat, bukan titik ini
    let mobile: String?
    let crimeTotal: Int?
    let currentTempC: Int?          // WeatherKit realtime
    let isSample: Bool              // true = fallback data contoh (server mati)

    /// "Collector Road · 320 m" (0 m = titik di dalam buffer jalan → label saja).
    var mainRoadText: String {
        guard let mainRoad else { return "—" }
        let name = AppLanguage.string(mainRoad)
        guard let distance = mainRoadDistanceM, distance > 0 else { return name }
        return "\(name) · \(formatMeters(distance))"
    }

    /// Overview template ter-lokalisasi; parameter diisi dari data backend.
    var overviewText: String {
        func loc(_ label: String) -> String { AppLanguage.string(label) }
        let dash = "—"
        return String(
            format: AppLanguage.string("overview_backend_template"),
            loc(floodRisk).lowercased(),
            loc(temperatureZone).lowercased(),
            currentTempC.map { "\($0)°C" } ?? dash,
            loc(airQuality).lowercased(),
            aqi.map(String.init) ?? dash,
            greenZoneCount > 0 ? loc(greenDominant).lowercased() : dash,
            loc(elevation).lowercased(),
            mainRoadText.lowercased(),
            String(facilities.reduce(0) { $0 + $1.count }),
            population.map { $0.formatted() } ?? dash
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Loader

enum IntelService {
    /// Gabungkan tiga sumber secara paralel: backend analyze, AQI Open-Meteo,
    /// dan suhu realtime WeatherKit. Sumber yang gagal diisi nil/fallback.
    static func load(for coordinate: CLLocationCoordinate2D) async -> PropertyIntel {
        async let analyzeTask = fetchAnalyze(coordinate: coordinate)
        async let aqiTask = fetchAQI(coordinate: coordinate)
        async let tempTask = fetchCurrentTempC(coordinate: coordinate)

        let (response, isSample) = await analyzeTask
        return build(
            from: response,
            aqi: await aqiTask,
            currentTempC: await tempTask,
            isSample: isSample
        )
    }

    // MARK: Backend /api/analyze (fallback: SampleAnalyze.json di bundle)

    private static func fetchAnalyze(
        coordinate: CLLocationCoordinate2D
    ) async -> (AnalyzeResponse?, isSample: Bool) {
        var components = URLComponents(
            url: BackendConfig.baseURL.appendingPathComponent("api/analyze"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
        ]
        if let url = components?.url {
            var request = URLRequest(url: url)
            request.timeoutInterval = BackendConfig.requestTimeout
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(AnalyzeResponse.self, from: data)
                print("[IntelService] backend OK: \(response.data.count) layers")
                return (response, false)
            } catch {
                print("[IntelService] backend FAILED (\(error.localizedDescription)) — pakai sample")
            }
        }
        return (loadSample(), true)
    }

    private static func loadSample() -> AnalyzeResponse? {
        guard let url = Bundle.main.url(forResource: "SampleAnalyze", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(AnalyzeResponse.self, from: data) else {
            print("[IntelService] SampleAnalyze.json tidak bisa dimuat")
            return nil
        }
        return response
    }

    // MARK: AQI — Open-Meteo Air Quality (gratis, tanpa API key)

    private struct OpenMeteoAQI: Decodable {
        struct Current: Decodable { let usAqi: Double? }
        let current: Current?
    }

    private static func fetchAQI(coordinate: CLLocationCoordinate2D) async -> Int? {
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality"
            + "?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&current=us_aqi"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let aqi = try decoder.decode(OpenMeteoAQI.self, from: data).current?.usAqi
            print("[IntelService] AQI OK: \(aqi.map(String.init(describing:)) ?? "nil")")
            return aqi.map { Int($0.rounded()) }
        } catch {
            print("[IntelService] AQI FAILED: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: Suhu realtime — WeatherKit

    private static func fetchCurrentTempC(coordinate: CLLocationCoordinate2D) async -> Int? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let celsius = weather.currentWeather.temperature.converted(to: .celsius).value
            return Int(celsius.rounded())
        } catch {
            print("[IntelService] WeatherKit FAILED: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: Mapping layer → PropertyIntel

    private static func build(
        from response: AnalyzeResponse?,
        aqi: Int?,
        currentTempC: Int?,
        isSample: Bool
    ) -> PropertyIntel {
        let layers = response?.data ?? []
        func first(_ name: String) -> LayerResult? { layers.first { $0.layer == name } }
        func all(_ name: String) -> [LayerResult] { layers.filter { $0.layer == name } }

        let population = first("population")?.attributes

        // Jalan utama terdekat: hanya Collector/Arterial, min jarak.
        let mainRoad = all("roads_buffer")
            .filter { $0.label.contains("Collector") || $0.label.contains("Arterial") }
            .min { ($0.distanceMeters ?? .max) < ($1.distanceMeters ?? .max) }

        // RTH dominan dalam 500 m: modus kelas; seri → kelas lebih hijau menang.
        let greenZones = all("green_spaces")
        let greenRank = ["Dense": 3, "Moderate": 2, "Sparse": 1]
        let dominant = Dictionary(grouping: greenZones, by: \.label)
            .max { lhs, rhs in
                lhs.value.count != rhs.value.count
                    ? lhs.value.count < rhs.value.count
                    : (greenRank[lhs.key] ?? 0) < (greenRank[rhs.key] ?? 0)
            }

        let facilities = all("public_facilities").map {
            FacilityInfo(
                category: $0.label.capitalized,
                count: $0.total ?? 1,
                distanceM: $0.distanceMeters ?? 0
            )
        }.sorted { $0.distanceM < $1.distanceM }

        func speedText(_ layer: LayerResult?) -> String? {
            guard let a = layer?.attributes, let dl = a.dlMbps, let ul = a.ulMbps else { return nil }
            return String(format: "%.0f / %.0f Mbps", dl, ul)
        }
        let wifi = first("wifi")

        return PropertyIntel(
            floodRisk: first("flood")?.label ?? "Unknown",
            temperatureZone: first("temperature")?.label ?? "Unknown",
            airQuality: first("air_quality")?.label ?? "Unknown",
            aqi: aqi,
            elevation: first("elevation")?.label ?? "Unknown",
            population: population?.jumlahPen.map { Int($0) },
            district: [population?.namaKec, population?.namaKab]
                .compactMap { $0?.capitalized }
                .joined(separator: ", ")
                .nilIfEmpty,
            greenDominant: dominant?.key ?? "Unknown",
            greenZoneCount: greenZones.count,
            mainRoad: mainRoad?.label,
            mainRoadDistanceM: mainRoad?.distanceMeters,
            facilities: facilities,
            wifi: speedText(wifi),
            wifiDistanceM: wifi?.distanceMeters,
            mobile: speedText(first("mobile_data")),
            crimeTotal: first("crime")?.attributes?.crimeTotal.map { Int($0) },
            currentTempC: currentTempC,
            isSample: isSample
        )
    }
}
