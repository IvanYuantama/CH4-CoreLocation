# Bali Property Map - Backend API

API backend untuk analisis properti berbasis spasial di Bali menggunakan PostGIS dan Express.js.

---

## Base URL

```
https://property-backend-khaki.vercel.app
```

---

## Endpoints Aktif

Terdapat dua endpoint yang saat ini digunakan:

```
GET /api/point/analyze?lat=&lng=
GET /api/layers/:layerKey?bbox=west,south,east,north
```

---

## 1. Point Analysis

Menganalisis kondisi suatu titik koordinat berdasarkan semua layer spasial yang tersedia.

### `GET /api/point/analyze`

```
GET /api/point/analyze?lat=-8.319946&lng=115.182006
```

**Query Parameters:**

| Parameter | Tipe   | Wajib | Keterangan                |
|-----------|--------|-------|---------------------------|
| `lat`     | number | Ya    | Latitude titik koordinat  |
| `lng`     | number | Ya    | Longitude titik koordinat |

**Response Sukses `200`:**

```json
{
  "success": true,
  "coordinates": {
    "lat": -8.319946,
    "lng": 115.182006
  },
  "overall_risk": "high",
  "data": [
    {
      "layer": "flood",
      "distance_meters": 0,
      "zone_value": "High Flood Risk",
      "label": "High Flood Risk",
      "color": "#FF3B30",
      "risk": "high",
      "attributes": {
        "area": "High Flood Risk"
      }
    },
    {
      "layer": "temperature",
      "distance_meters": 0,
      "zone_value": "Hot",
      "label": "Hot",
      "color": "#FF9500",
      "risk": "medium",
      "attributes": {
        "suhu": "Hot"
      }
    },
    {
      "layer": "air_quality",
      "distance_meters": 0,
      "zone_value": "Low",
      "label": "Good",
      "color": "#34C759",
      "risk": "low",
      "attributes": {
        "polusi": "Low"
      }
    },
    {
      "layer": "elevation",
      "distance_meters": 0,
      "zone_value": "Lowland",
      "label": "Lowland",
      "color": "#FF9500",
      "risk": "high",
      "attributes": {
        "ketinggian": "Lowland"
      }
    }
  ]
}
```

**Nilai `overall_risk`:**

| Nilai     | Arti                                      |
|-----------|-------------------------------------------|
| `low`     | Semua layer berisiko rendah               |
| `medium`  | Terdapat satu atau lebih risiko sedang    |
| `high`    | Terdapat satu atau lebih risiko tinggi    |
| `unknown` | Data tidak ditemukan dalam radius 5000 m  |

**Response Error:**

```json
// 400 - Parameter tidak lengkap
{ "error": "lat dan lng wajib diisi" }

// 400 - Nilai bukan angka
{ "error": "lat dan lng harus berupa angka" }

// 500 - Error database
{ "error": "pesan error dari database" }
```

---

## 2. Map Layer GeoJSON

Mengambil data polygon GeoJSON satu layer untuk ditampilkan sebagai overlay peta.

### `GET /api/layers/:layerKey`

Parameter `bbox` wajib disertakan untuk mencegah overload server.

```
GET /api/layers/flood?bbox=115.1,-8.8,115.3,-8.6
```

**Path Parameter:**

| Parameter  | Tipe   | Wajib | Keterangan          |
|------------|--------|-------|---------------------|
| `layerKey` | string | Ya    | Kunci layer (lihat tabel di bawah) |

**Query Parameter:**

| Parameter | Tipe   | Wajib | Contoh                   | Keterangan                             |
|-----------|--------|-------|--------------------------|----------------------------------------|
| `bbox`    | string | Ya    | `115.1,-8.8,115.3,-8.6` | Bounding box: `west,south,east,north`  |

**Layer yang tersedia:**

| `layerKey`          | Tabel Database      | Field Klasifikasi    |
|---------------------|---------------------|----------------------|
| `flood`             | `flood_zones`       | `area`               |
| `temperature`       | `temperature_zones` | `suhu`               |
| `air_quality`       | `air_quality`       | `polusi`             |
| `green_spaces`      | `green_spaces`      | `rth`                |
| `population`        | `population_data`   | `jumlah_pen`         |
| `elevation`         | `elevation_zones`   | `ketinggian`         |
| `roads_buffer`      | `roads_buffer`      | `remark`             |
| `public_facilities` | `public_facilities` | `remark`             |

**Response Sukses `200`:**

```json
{
  "success": true,
  "layer": "flood",
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": ["..."]
      },
      "properties": {
        "layer": "flood",
        "zone_value": "High Flood Risk",
        "label": "High Flood Risk",
        "color": "#FF3B30",
        "risk": "high"
      }
    }
  ]
}
```

**Response Error:**

```json
// 400 - bbox tidak disertakan
{ "error": "Parameter ?bbox=minLng,minLat,maxLng,maxLat wajib diisi agar server tidak overload." }

// 400 - Format bbox tidak valid
{ "error": "Format bbox tidak valid. Gunakan angka: minLng,minLat,maxLng,maxLat" }

// 404 - layerKey tidak dikenali
{
  "error": "Layer 'xyz' tidak ditemukan.",
  "available": ["flood","temperature","air_quality","green_spaces","public_facilities","population","elevation","roads_buffer"]
}

// 500 - Error database
{ "error": "pesan error dari database" }
```

---

## Skema Warna per Layer

| Layer               | Low / Aman       | Medium                | High / Berisiko  |
|---------------------|------------------|-----------------------|------------------|
| `flood`             | Low Flood Risk   | -                     | High Flood Risk  |
| `temperature`       | Cool / Very Cool | Moderate / Hot        | Very Hot         |
| `air_quality`       | Low (Good)       | Medium (Moderate)     | High (Bad)       |
| `population`        | < 20.000         | 20.000 - 100.000      | > 100.000        |
| `elevation`         | Highland         | Midland               | Lowland          |
| `green_spaces`      | Dense            | Moderate / Sparse     | -                |
| `public_facilities` | Semua zona       | -                     | -                |
| `roads_buffer`      | Semua zona       | -                     | -                |

---

## Contoh Pengujian

### Menggunakan curl

**Point Analysis:**

```bash
curl "https://property-backend-khaki.vercel.app/api/point/analyze?lat=-8.319946&lng=115.182006"
```

**Map Layer GeoJSON:**

```bash
curl "https://property-backend-khaki.vercel.app/api/layers/flood?bbox=115.1,-8.8,115.3,-8.6"
```

### Menggunakan HTTPie

```bash
http GET "https://property-backend-khaki.vercel.app/api/point/analyze" lat==-8.319946 lng==115.182006

http GET "https://property-backend-khaki.vercel.app/api/layers/flood" bbox==115.1,-8.8,115.3,-8.6
```

### Menggunakan JavaScript (fetch)

```javascript
// Point Analysis
const res = await fetch(
  "https://property-backend-khaki.vercel.app/api/point/analyze?lat=-8.319946&lng=115.182006"
);
const data = await res.json();
console.log(data.overall_risk);

// Map Layer GeoJSON
const layerRes = await fetch(
  "https://property-backend-khaki.vercel.app/api/layers/flood?bbox=115.1,-8.8,115.3,-8.6"
);
const layerData = await layerRes.json();
console.log(layerData.features.length);
```

---

## Implementasi di Swift (MapKit)

Berikut adalah panduan lengkap untuk mengintegrasikan kedua endpoint ke dalam aplikasi iOS menggunakan MapKit.

### 1. Model Data

Definisikan struktur data yang sesuai dengan response API.

```swift
// MARK: - Point Analysis

struct PointAnalysisResponse: Decodable {
    let success: Bool
    let coordinates: Coordinates
    let overallRisk: String
    let data: [LayerResult]

    enum CodingKeys: String, CodingKey {
        case success, coordinates, data
        case overallRisk = "overall_risk"
    }
}

struct Coordinates: Decodable {
    let lat: Double
    let lng: Double
}

struct LayerResult: Decodable {
    let layer: String
    let distanceMeters: Int
    let zoneValue: String
    let label: String
    let color: String
    let risk: String

    enum CodingKeys: String, CodingKey {
        case layer, label, color, risk
        case distanceMeters = "distance_meters"
        case zoneValue = "zone_value"
    }
}

// MARK: - GeoJSON Layer

struct GeoJSONResponse: Decodable {
    let success: Bool
    let layer: String
    let type: String
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Decodable {
    let type: String
    let geometry: GeoJSONGeometry
    let properties: FeatureProperties
}

struct GeoJSONGeometry: Decodable {
    let type: String
    let coordinates: AnyCodable  // Gunakan AnyCodable atau decode manual
}

struct FeatureProperties: Decodable {
    let layer: String
    let zoneValue: String
    let label: String
    let color: String
    let risk: String

    enum CodingKeys: String, CodingKey {
        case layer, label, color, risk
        case zoneValue = "zone_value"
    }
}
```

### 2. API Service

Buat service terpisah untuk menangani semua request ke backend.

```swift
import Foundation
import CoreLocation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "URL tidak valid."
        case .invalidResponse:   return "Response dari server tidak valid."
        case .decodingFailed(let e): return "Gagal decode data: \(e.localizedDescription)"
        case .serverError(let msg):  return "Server error: \(msg)"
        }
    }
}

final class BaliPropertyAPIService {

    static let shared = BaliPropertyAPIService()
    private let baseURL = "https://property-backend-khaki.vercel.app"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - Point Analysis

    func analyzePoint(
        coordinate: CLLocationCoordinate2D
    ) async throws -> PointAnalysisResponse {
        var components = URLComponents(string: "\(baseURL)/api/point/analyze")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude))
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PointAnalysisResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - Map Layer GeoJSON

    func fetchLayer(
        layerKey: String,
        bbox: MKCoordinateRegion
    ) async throws -> Data {
        let west  = bbox.center.longitude - bbox.span.longitudeDelta / 2
        let east  = bbox.center.longitude + bbox.span.longitudeDelta / 2
        let south = bbox.center.latitude  - bbox.span.latitudeDelta  / 2
        let north = bbox.center.latitude  + bbox.span.latitudeDelta  / 2

        var components = URLComponents(string: "\(baseURL)/api/layers/\(layerKey)")!
        components.queryItems = [
            URLQueryItem(name: "bbox", value: "\(west),\(south),\(east),\(north)")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return data
    }
}
```

### 3. Menampilkan Overlay Polygon di MapKit

MapKit mendukung GeoJSON secara native melalui `MKGeoJSONDecoder`. Gunakan ini untuk mengonversi response layer menjadi overlay peta.

```swift
import MapKit

final class MapLayerManager {

    // Tambahkan overlay GeoJSON ke MKMapView
    func addGeoJSONOverlay(
        data: Data,
        to mapView: MKMapView,
        layerKey: String
    ) {
        let decoder = MKGeoJSONDecoder()

        guard let features = try? decoder.decode(data) else {
            print("Gagal decode GeoJSON untuk layer: \(layerKey)")
            return
        }

        for feature in features {
            guard let geoFeature = feature as? MKGeoJSONFeature else { continue }

            // Ambil properties untuk warna polygon
            var fillColor = UIColor.systemGray
            if let propsData = geoFeature.properties,
               let props = try? JSONDecoder().decode(FeatureProperties.self, from: propsData) {
                fillColor = UIColor(hex: props.color) ?? .systemGray
            }

            for geometry in geoFeature.geometry {
                switch geometry {
                case let polygon as MKPolygon:
                    mapView.addOverlay(polygon)
                    // Simpan warna ke dictionary untuk diakses di renderer
                    overlayColorMap[polygon] = fillColor

                case let multiPolygon as MKMultiPolygon:
                    mapView.addOverlay(multiPolygon)
                    overlayColorMap[multiPolygon] = fillColor

                default:
                    break
                }
            }
        }
    }

    // Dictionary untuk menyimpan warna per overlay
    private var overlayColorMap: [AnyHashable: UIColor] = [:]

    func color(for overlay: MKOverlay) -> UIColor {
        return overlayColorMap[AnyHashable(overlay as AnyObject)] ?? UIColor.systemGray.withAlphaComponent(0.4)
    }
}
```

### 4. Renderer Overlay

Implementasikan `MKMapViewDelegate` untuk merender warna polygon sesuai data dari API.

```swift
extension YourViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let fillColor = layerManager.color(for: overlay)

        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor   = fillColor.withAlphaComponent(0.4)
            renderer.strokeColor = fillColor
            renderer.lineWidth   = 1.0
            return renderer
        }

        if let multiPolygon = overlay as? MKMultiPolygon {
            let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            renderer.fillColor   = fillColor.withAlphaComponent(0.4)
            renderer.strokeColor = fillColor
            renderer.lineWidth   = 1.0
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }
}
```

### 5. Analisis Titik Koordinat

Tampilkan detail risiko ketika pengguna mengetuk lokasi di peta.

```swift
extension YourViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let coordinate = view.annotation?.coordinate else { return }

        Task {
            do {
                let result = try await BaliPropertyAPIService.shared.analyzePoint(
                    coordinate: coordinate
                )
                await MainActor.run {
                    showRiskBottomSheet(result: result)
                }
            } catch {
                await MainActor.run {
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func showRiskBottomSheet(result: PointAnalysisResponse) {
        // Tampilkan sheet berisi overall_risk dan detail per layer
        let overallRisk = result.overallRisk  // "low", "medium", "high", "unknown"
        let layers = result.data

        // Contoh: warna badge risiko keseluruhan
        let badgeColor: UIColor
        switch overallRisk {
        case "high":    badgeColor = UIColor(hex: "#FF3B30")!
        case "medium":  badgeColor = UIColor(hex: "#FF9500")!
        case "low":     badgeColor = UIColor(hex: "#34C759")!
        default:        badgeColor = UIColor(hex: "#8E8E93")!
        }

        // Lanjutkan ke UI layer Anda
        _ = badgeColor
        _ = layers
    }
}
```

### 6. Memuat Layer saat Region Berubah

Muat ulang data layer secara otomatis ketika pengguna menggeser atau memperbesar peta.

```swift
extension YourViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let currentRegion = mapView.region

        // Hindari request terlalu sering dengan debounce
        layerLoadTask?.cancel()
        layerLoadTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 detik
            guard !Task.isCancelled else { return }
            await loadFloodLayer(for: currentRegion)
        }
    }

    private var layerLoadTask: Task<Void, Never>?

    func loadFloodLayer(for region: MKCoordinateRegion) async {
        do {
            let data = try await BaliPropertyAPIService.shared.fetchLayer(
                layerKey: "flood",
                bbox: region
            )
            await MainActor.run {
                // Hapus overlay lama sebelum menambah yang baru
                let existingOverlays = mapView.overlays
                mapView.removeOverlays(existingOverlays)

                layerManager.addGeoJSONOverlay(data: data, to: mapView, layerKey: "flood")
            }
        } catch {
            print("Gagal memuat layer flood: \(error.localizedDescription)")
        }
    }
}
```

### 7. Helper: UIColor dari Hex String

```swift
extension UIColor {
    convenience init?(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }

        guard hexStr.count == 6,
              let value = UInt64(hexStr, radix: 16) else { return nil }

        self.init(
            red:   CGFloat((value & 0xFF0000) >> 16) / 255,
            green: CGFloat((value & 0x00FF00) >> 8)  / 255,
            blue:  CGFloat( value & 0x0000FF)         / 255,
            alpha: 1.0
        )
    }
}
```

---

## Catatan Implementasi

**Jaringan:** Backend sudah berjalan di HTTPS melalui Vercel, sehingga tidak diperlukan konfigurasi `NSAppTransportSecurity` tambahan di `Info.plist`. Aplikasi iOS dapat langsung melakukan request ke `https://property-backend-khaki.vercel.app` tanpa pengecualian ATS.

**Performa overlay:** Untuk data GeoJSON berukuran besar, pertimbangkan menyimpan hasil fetch dalam cache lokal berdasarkan kombinasi `layerKey` dan `bbox` agar tidak melakukan request berulang pada region yang sama.

**Konkruensi:** Semua pembaruan UI (`addOverlay`, `removeOverlays`) harus dijalankan di `MainActor`. Seluruh contoh kode di atas sudah memenuhi hal ini.
