# Backend Documentation

Complete data structure documentation per layer from the `/api/analyze` endpoint.

---

## Response Structure

```
{
  success:     Bool
  coordinates: { lat: Double, lng: Double }
  data:        [LayerResult]
}
```

### LayerResult (each item in `data`)

| Field             | Tipe   | Keterangan                                                                |
| ----------------- | ------ | ------------------------------------------------------------------------- |
| `layer`           | String | Layer name                                                                |
| `distance_meters` | Int    | Distance from coordinate point to zone. `0` = point is inside the zone    |
| `label`           | String | Human-readable label from classification                                  |
| `color`           | String | Hex color for UI (`#RRGGBB`)                                              |
| `attributes`      | Object | Raw data from database (differs per layer)                                |
| `total`           | Int    | Number of facilities in the category. Only present in `public_facilities` |

---

## Data Retrieval Guide per Layer (Frontend)

Quick reference for which fields are relevant to display in the UI.

| Layer               | Take From                                  | Notes                     |
| ------------------- | ------------------------------------------ | ------------------------- |
| `flood`             | `attributes.area`                          |                           |
| `temperature`       | `attributes.suhu`                          |                           |
| `air_quality`       | `label`                                    |                           |
| `green_spaces`      | `label`                                    |                           |
| `population`        | `attributes.jumlah_pen`                    |                           |
| `elevation`         | `label`                                    |                           |
| `roads_buffer`      | `distance_meters`, `label`                 | Can appear multiple times |
| `public_facilities` | `distance_meters`, `label`, `total`        | Can appear multiple times |
| `wifi`              | `attributes.dl_mbps`, `attributes.ul_mbps` |                           |
| `mobile_data`       | `attributes.dl_mbps`, `attributes.ul_mbps` |                           |
| `crime`             | `attributes.crime_total`                   |                           |

---

## Layer: `flood`

**Classification field:** `area` (String)

| Zone Value        | Label           | Color     |
| ----------------- | --------------- | --------- |
| `Low Flood Risk`  | Low Flood Risk  | `#34C759` |
| `High Flood Risk` | High Flood Risk | `#FF3B30` |
| _(other)_         | Unknown         | `#8E8E93` |

**Attributes:**

| Field  | Tipe   | Keterangan          |
| ------ | ------ | ------------------- |
| `area` | String | Zone classification |

**Example:**

```json
{
  "layer": "flood",
  "distance_meters": 0,
  "label": "Low Flood Risk",
  "color": "#34C759",
  "attributes": {
    "area": "Low Flood Risk"
  }
}
```

---

## Layer: `temperature`

**Classification field:** `suhu` (String)

| Zone Value  | Label     | Color     |
| ----------- | --------- | --------- |
| `Very Cool` | Very Cool | `#00ff84` |
| `Cool`      | Cool      | `#00ff84` |
| `Moderate`  | Moderate  | `#FFCC00` |
| `Hot`       | Hot       | `#FF9500` |
| `Very Hot`  | Very Hot  | `#FF3B30` |
| _(other)_   | Unknown   | `#8E8E93` |

**Attributes:**

| Field  | Tipe   | Keterangan                 |
| ------ | ------ | -------------------------- |
| `suhu` | String | Temperature classification |

**Example:**

```json
{
  "layer": "temperature",
  "distance_meters": 0,
  "label": "Cool",
  "color": "#00ff84",
  "attributes": {
    "suhu": "Cool"
  }
}
```

---

## Layer: `air_quality`

**Classification field:** `polusi` (String)

| Zone Value | Label    | Color     |
| ---------- | -------- | --------- |
| `Low`      | Good     | `#34C759` |
| `Medium`   | Moderate | `#FF9500` |
| `High`     | Bad      | `#FF3B30` |
| _(other)_  | Unknown  | `#8E8E93` |

**Attributes:**

| Field        | Tipe   | Keterangan               |
| ------------ | ------ | ------------------------ |
| `polusi`     | String | Pollution classification |
| `objectid`   | Int    | Object ID in database    |
| `shape_area` | Double | Area size (degrees²)     |
| `shape_leng` | Double | Perimeter length         |

**Example:**

```json
{
  "layer": "air_quality",
  "distance_meters": 0,
  "label": "Good",
  "color": "#34C759",
  "attributes": {
    "polusi": "Low",
    "objectid": 1,
    "shape_area": 0.198562468143,
    "shape_leng": 5.88620668896
  }
}
```

---

## Layer: `green_spaces`

**Classification field:** `rth` (String)

| Zone Value | Label    | Color     |
| ---------- | -------- | --------- |
| `Dense`    | Dense    | `#34C759` |
| `Moderate` | Moderate | `#FFCC00` |
| `Sparse`   | Sparse   | `#FF9500` |
| _(other)_  | Unknown  | `#8E8E93` |

**Attributes:**

| Field      | Tipe   | Keterangan                 |
| ---------- | ------ | -------------------------- |
| `rth`      | String | Green space classification |
| `id`       | Int    | ID grid                    |
| `gridcode` | Int    | Numeric grid code          |

**Example:**

```json
{
  "layer": "green_spaces",
  "distance_meters": 0,
  "label": "Dense",
  "color": "#34C759",
  "attributes": {
    "id": 12,
    "rth": "Dense",
    "gridcode": 3
  }
}
```

---

## Layer: `population`

**Classification field:** `jumlah_pen` (Double)

No zone classification. Label displays the population count in the format `{n} people`.

| Kondisi      | Color     |
| ------------ | --------- |
| Valid number | `#5AC8FA` |
| Invalid      | `#8E8E93` |

**Attributes (main fields):**

| Field        | Tipe   | Keterangan                        |
| ------------ | ------ | --------------------------------- |
| `nama_kab`   | String | Regency name                      |
| `nama_kec`   | String | District name                     |
| `jumlah_pen` | Double | Total population count            |
| `jumlah_kk`  | Double | Number of households              |
| `pria`       | Double | Male population count             |
| `wanita`     | Double | Female population count           |
| `islam`      | Double | Muslim population count           |
| `hindu`      | Double | Hindu population count            |
| `kristen`    | Double | Protestant population count       |
| `katholik`   | Double | Catholic population count         |
| `budha`      | Double | Buddhist population count         |
| `konghucu`   | Double | Confucian population count        |
| `kawin`      | Double | Married                           |
| `belum_kawi` | Double | Single / Never married            |
| `cerai_hidu` | Double | Divorced                          |
| `cerai_mati` | Double | Widowed                           |
| `tamat_sd`   | Double | Completed primary school          |
| `sltp`       | Double | Completed junior high school      |
| `slta`       | Double | Completed senior high school      |
| `d1_dan_d2`  | Double | Diploma D1/D2                     |
| `d3`         | Double | Diploma D3                        |
| `s1`         | Double | Bachelor's degree                 |
| `s2`         | Double | Master's degree                   |
| `s3`         | Double | Doctoral degree                   |
| `belum_tama` | Double | Did not complete primary school   |
| `belum_tida` | Double | Never attended school             |
| `tidak_blm_` | Double | Not / never in school             |
| `wiraswasta` | Double | Occupation: self-employed         |
| `pelajar_ma` | Double | Student                           |
| `mengurus_r` | Double | Homemaker                         |
| `pensiunan`  | Double | Retired                           |
| `perdaganga` | Double | Trader                            |
| `guru`       | Double | Guru                              |
| `perawat`    | Double | Nurse                             |
| `nelayan`    | Double | Fisherman                         |
| `pengacara`  | Double | Lawyer                            |
| `lainnya`    | Double | Other occupations                 |
| `u0`–`u75`   | Double | Age distribution per 5-year group |

**Example:**

```json
{
  "layer": "population",
  "distance_meters": 0,
  "label": "55352 people",
  "color": "#5AC8FA",
  "attributes": {
    "nama_kab": "KAB. TABANAN",
    "nama_kec": "BATURITI",
    "jumlah_pen": 55352,
    "jumlah_kk": 16798,
    "pria": 27818,
    "wanita": 27534
  }
}
```

---

## Layer: `elevation`

**Classification field:** `ketinggian` (String)

| Zone Value | Label    | Color     |
| ---------- | -------- | --------- |
| `Lowland`  | Lowland  | `#FF9500` |
| `Midland`  | Midland  | `#34C759` |
| `Highland` | Highland | `#5AC8FA` |
| _(other)_  | Unknown  | `#8E8E93` |

**Attributes:**

| Field        | Tipe   | Keterangan               |
| ------------ | ------ | ------------------------ |
| `ketinggian` | String | Elevation classification |

**Example:**

```json
{
  "layer": "elevation",
  "distance_meters": 0,
  "label": "Highland",
  "color": "#5AC8FA",
  "attributes": {
    "ketinggian": "Highland"
  }
}
```

---

## Layer: `roads_buffer`

**Classification field:** `remark` (String)

No zone classification. Label follows the `remark` value directly. Appears multiple times as a single point can fall within multiple road buffers simultaneously.

| Zone Value       | Label          | Color     |
| ---------------- | -------------- | --------- |
| `Collector Road` | Collector Road | `#8E8E93` |
| `Local Road`     | Local Road     | `#8E8E93` |
| `Other Road`     | Other Road     | `#8E8E93` |
| `Footpath`       | Footpath       | `#8E8E93` |
| _(other)_        | Unknown        | `#8E8E93` |

**Attributes:**

| Field        | Tipe   | Keterangan              |
| ------------ | ------ | ----------------------- |
| `remark`     | String | Road type               |
| `objectid_1` | Int    | Object ID in database   |
| `shape_area` | Double | Buffer area size (m²)   |
| `shape_leng` | Double | Perimeter length buffer |

**Example:**

```json
{
  "layer": "roads_buffer",
  "distance_meters": 0,
  "label": "Collector Road",
  "color": "#8E8E93",
  "attributes": {
    "remark": "Collector Road",
    "objectid_1": 2,
    "shape_area": 828143032.733,
    "shape_leng": 1514632.82135
  }
}
```

---

## Layer: `public_facilities`

**Classification field:** `kategori` (String)

Appears multiple times, sorted by nearest first. Each item represents one facility category. `total` indicates the number of facilities in that category within the search radius.

| Kategori contoh | Keterangan              |
| --------------- | ----------------------- |
| `kesehatan`     | Health facility         |
| `pendidikan`    | Education facility      |
| _(nilai lain)_  | Follows database values |

**Attributes:**

| Field      | Tipe   | Keterangan        |
| ---------- | ------ | ----------------- |
| `kategori` | String | Facility category |

**Additional field at root level (not inside attributes):**

| Field   | Tipe | Keterangan                            |
| ------- | ---- | ------------------------------------- |
| `total` | Int  | Number of facilities in this category |

**Example:**

```json
{
  "layer": "public_facilities",
  "distance_meters": 771,
  "label": "kesehatan",
  "color": "#8E8E93",
  "attributes": {
    "kategori": "kesehatan"
  },
  "total": 1
}
```

---

## Layer: `wifi`

No zone classification. Label displays download and upload speeds directly.

| Kondisi        | Color     |
| -------------- | --------- |
| Data available | `#5AC8FA` |

**Attributes:**

| Field        | Tipe   | Keterangan                  |
| ------------ | ------ | --------------------------- |
| `dl_mbps`    | Double | Download speed (Mbps)       |
| `ul_mbps`    | Double | Upload speed (Mbps)         |
| `avg_lat_ms` | Int    | Average latency (ms)        |
| `avg_d_kbps` | Int    | Average download (Kbps)     |
| `avg_u_kbps` | Int    | Average upload (Kbps)       |
| `tests`      | Int    | Number of tests conducted   |
| `devices`    | Int    | Number of devices tested    |
| `quadkey`    | String | Map grid key (Bing quadkey) |

**Example:**

```json
{
  "layer": "wifi",
  "distance_meters": 0,
  "label": "Download 68.9 Mbps, Upload 52.8 Mbps",
  "color": "#5AC8FA",
  "attributes": {
    "dl_mbps": 68.9,
    "ul_mbps": 52.77,
    "avg_lat_ms": 28,
    "avg_d_kbps": 68905,
    "avg_u_kbps": 52772,
    "tests": 9,
    "devices": 2,
    "quadkey": "3101020333303222"
  }
}
```

---

## Layer: `mobile_data`

Identical structure to `wifi`, but measures mobile network speed.

**Attributes:**

| Field        | Tipe   | Keterangan                  |
| ------------ | ------ | --------------------------- |
| `dl_mbps`    | Double | Download speed (Mbps)       |
| `ul_mbps`    | Double | Upload speed (Mbps)         |
| `avg_lat_ms` | Int    | Average latency (ms)        |
| `avg_d_kbps` | Int    | Average download (Kbps)     |
| `avg_u_kbps` | Int    | Average upload (Kbps)       |
| `tests`      | Int    | Number of tests conducted   |
| `devices`    | Int    | Number of devices tested    |
| `quadkey`    | String | Map grid key (Bing quadkey) |

**Example:**

```json
{
  "layer": "mobile_data",
  "distance_meters": 0,
  "label": "Download 30.9 Mbps, Upload 14.2 Mbps",
  "color": "#5AC8FA",
  "attributes": {
    "dl_mbps": 30.92,
    "ul_mbps": 14.21,
    "avg_lat_ms": 16,
    "avg_d_kbps": 30921,
    "avg_u_kbps": 14213,
    "tests": 1,
    "devices": 1,
    "quadkey": "3101020333303222"
  }
}
```

---

## Layer: `crime`

No zone classification. Label displays total criminal cases.

| Kondisi        | Color     |
| -------------- | --------- |
| Data available | `#FF9500` |

**Attributes:**

| Field            | Tipe   | Keterangan                        |
| ---------------- | ------ | --------------------------------- |
| `crime_total`    | Int    | Total criminal cases              |
| `crime_cleared`  | Int    | Number of cases resolved          |
| `clearance_rate` | Double | Case resolution rate (%)          |
| `crime_rate`     | Double | Crime rate per 100,000 population |
| `tahun`          | Int    | Data year                         |
| `nama_kab`       | String | Regency name                      |
| `jumlah_pen`     | Double | Regency population count          |
| `jumlah_kk`      | Double | Number of households kabupaten    |
| `sumber`         | String | Data source                       |

**Example:**

```json
{
  "layer": "crime",
  "distance_meters": 0,
  "label": "1057 cases",
  "color": "#FF9500",
  "attributes": {
    "crime_total": 1057,
    "crime_cleared": 844,
    "clearance_rate": 79.85,
    "crime_rate": 226.78,
    "tahun": 2023,
    "nama_kab": "KAB. TABANAN",
    "jumlah_pen": 476472,
    "jumlah_kk": 153216,
    "sumber": "BPS - Statistik Kriminal Provinsi Bali 2023 (Polda Bali)"
  }
}
```

---

## Multiplicity Notes

| Layer               | Occurrences | Reason                                        |
| ------------------- | ----------- | --------------------------------------------- |
| `flood`             | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `temperature`       | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `air_quality`       | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `green_spaces`      | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `population`        | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `elevation`         | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `wifi`              | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `mobile_data`       | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `crime`             | Max. 1 time | `ST_Intersects` with `LIMIT 1`                |
| `roads_buffer`      | Multiple    | A point can fall within multiple road buffers |
| `public_facilities` | Multiple    | Radius search per facility category           |
