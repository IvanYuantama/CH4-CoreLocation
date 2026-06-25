# Bali Property Map - Backend API

API backend untuk analisis properti berbasis spasial di Bali menggunakan PostGIS + Express.js.

---

## Base URL

```
http://localhost:3000
```

---

## Endpoints

### Health Check

```
GET /health
```

**Response:**
```json
{ "status": "ok" }
```

---

## Point Analysis - `/api/point`

Menganalisis kondisi suatu titik koordinat berdasarkan semua layer spasial.

### `GET /api/point/analyze`

```
GET /api/point/analyze?lat=-8.6500&lng=115.2167
```

**Query Parameters:**

| Parameter | Tipe   | Wajib | Keterangan               |
|-----------|--------|-------|--------------------------|
| `lat`     | number | Ya    | Latitude titik koordinat  |
| `lng`     | number | Ya    | Longitude titik koordinat |

**Response Sukses `200`:**
```json
{
  "success": true,
  "coordinates": {
    "lat": -8.65,
    "lng": 115.2167
  },
  "overall_risk": "high",
  "summary": [
    { "layer": "flood",             "label": "Risiko Banjir Tinggi",  "color": "#FF3B30", "risk": "high"   },
    { "layer": "temperature",       "label": "Suhu Panas",            "color": "#FF9500", "risk": "medium" },
    { "layer": "air_quality",       "label": "Kualitas Udara Baik",   "color": "#34C759", "risk": "low"    },
    { "layer": "green_spaces",      "label": "Ruang Terbuka Hijau",   "color": "#30D158", "risk": "low"    },
    { "layer": "public_facilities", "label": "Fasilitas Umum",        "color": "#007AFF", "risk": "low"    },
    { "layer": "population",        "label": "Kepadatan Tinggi",      "color": "#FF9500", "risk": "medium" },
    { "layer": "elevation",         "label": "Dataran Rendah",        "color": "#FF9500", "risk": "medium" },
    { "layer": "roads_buffer",      "label": "Buffer Jalan",          "color": "#8E8E93", "risk": "low"    }
  ],
  "layers": [
    {
      "layer": "flood",
      "distance_meters": 243,
      "zone_value": "High Flood Risk",
      "label": "Risiko Banjir Tinggi",
      "color": "#FF3B30",
      "risk": "high",
      "data": { "ogc_fid": 1, "area": "High Flood Risk" }
    }
  ]
}
```

**Response Error:**
```json
// 400 - lat atau lng tidak diisi
{ "error": "lat dan lng wajib diisi" }

// 500 - error database
{ "error": "pesan error dari database" }
```

**Nilai `overall_risk`:**

| Nilai     | Arti                                     |
|-----------|------------------------------------------|
| `low`     | Semua layer aman                         |
| `medium`  | Ada satu atau lebih layer risiko sedang  |
| `high`    | Ada satu atau lebih layer risiko tinggi  |
| `unknown` | Data tidak ditemukan dalam radius 5000 m |

---

## Map Layers - `/api/maplayer`

Mengambil data polygon GeoJSON untuk ditampilkan sebagai overlay peta di MapKit iOS.

---

### `GET /api/maplayer/layers`

Mengambil semua layer sekaligus.

```
GET /api/maplayer/layers
GET /api/maplayer/layers?layers=flood,temperature
GET /api/maplayer/layers?bbox=115.1,-8.8,115.3,-8.6
```

**Query Parameters (opsional):**

| Parameter | Tipe   | Contoh                   | Keterangan                            |
|-----------|--------|--------------------------|---------------------------------------|
| `layers`  | string | `flood,temperature`      | Filter layer tertentu, pisah koma     |
| `bbox`    | string | `115.1,-8.8,115.3,-8.6` | Bounding box: `west,south,east,north` |

**Response Sukses `200`:**
```json
{
  "success": true,
  "layers": {
    "flood": {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": { "type": "MultiPolygon", "coordinates": ["..."] },
          "properties": {
            "layer": "flood",
            "zone_value": "High Flood Risk",
            "label": "Risiko Banjir Tinggi",
            "color": "#FF3B30",
            "risk": "high"
          }
        }
      ]
    },
    "temperature": { "..." },
    "air_quality": { "..." },
    "green_spaces": { "..." },
    "public_facilities": { "..." },
    "population": { "..." },
    "elevation": { "..." },
    "roads_buffer": { "..." }
  }
}
```

---

### `GET /api/maplayer/layers/:layerKey`

Mengambil satu layer saja. Cocok untuk lazy loading di iOS.

```
GET /api/maplayer/layers/flood
GET /api/maplayer/layers/flood?bbox=115.1,-8.8,115.3,-8.6
```

**Layer yang tersedia:**

| `:layerKey`         | Tabel DB            | Field Klasifikasi    |
|---------------------|---------------------|----------------------|
| `flood`             | `flood_zones`       | `area`               |
| `temperature`       | `temperature_zones` | `suhu`               |
| `air_quality`       | `air_quality`       | `polusi`             |
| `green_spaces`      | `green_spaces`      | `type`               |
| `public_facilities` | `public_facilities` | `facility_type`      |
| `population`        | `population_data`   | `density_category`   |
| `elevation`         | `elevation_zones`   | `elevation_category` |
| `roads_buffer`      | `roads_buffer`      | `road_type`          |

**Response Sukses `200`:**
```json
{
  "success": true,
  "layer": "flood",
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "MultiPolygon", "coordinates": ["..."] },
      "properties": {
        "layer": "flood",
        "zone_value": "High Flood Risk",
        "label": "Risiko Banjir Tinggi",
        "color": "#FF3B30",
        "risk": "high"
      }
    }
  ]
}
```

**Response Error:**
```json
// 404 - layerKey tidak dikenali
{
  "error": "Layer 'xyz' tidak ditemukan.",
  "available": ["flood","temperature","air_quality","green_spaces","public_facilities","population","elevation","roads_buffer"]
}
```

---

### `GET /api/maplayer/legend`

Mengambil konfigurasi warna dan label semua layer untuk UI legenda di iOS.

```
GET /api/maplayer/legend
```

**Response Sukses `200`:**
```json
{
  "success": true,
  "legend": {
    "flood": {
      "zones": [
        { "zone_value": "Low Flood Risk",   "label": "Risiko Banjir Rendah", "color": "#34C759", "risk": "low"    },
        { "zone_value": "Medium Flood Risk","label": "Risiko Banjir Sedang", "color": "#FF9500", "risk": "medium" },
        { "zone_value": "High Flood Risk",  "label": "Risiko Banjir Tinggi", "color": "#FF3B30", "risk": "high"   }
      ],
      "default": { "color": "#8E8E93", "label": "Tidak Diketahui", "risk": "unknown" }
    },
    "temperature": { "..." },
    "air_quality": { "..." },
    "green_spaces": { "..." },
    "public_facilities": { "..." },
    "population": { "..." },
    "elevation": { "..." },
    "roads_buffer": { "..." }
  }
}
```

---

## Skema Warna per Layer

| Layer               | Low / Aman       | Medium            | High / Berisiko  |
|---------------------|------------------|-------------------|------------------|
| `flood`             | Low Flood Risk   | Medium Flood Risk | High Flood Risk  |
| `temperature`       | Cool             | Warm / Hot        | Very Hot         |
| `air_quality`       | Low (baik)       | Medium            | High (buruk)     |
| `population`        | Low              | Medium / High     | Very High        |
| `elevation`         | High / Very High | Low               | -                |
| `green_spaces`      | Semua zona       | -                 | -                |
| `public_facilities` | Semua zona       | -                 | -                |
| `roads_buffer`      | Semua zona       | -                 | -                |

---

## Ringkasan Semua Endpoint

```
GET /health

GET /api/point/analyze?lat=&lng=

GET /api/maplayer/layers
GET /api/maplayer/layers?layers=flood,temperature
GET /api/maplayer/layers?bbox=west,south,east,north
GET /api/maplayer/layers/:layerKey
GET /api/maplayer/layers/:layerKey?bbox=west,south,east,north
GET /api/maplayer/legend
```
