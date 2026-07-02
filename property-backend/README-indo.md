# Layer Data Documentation

Dokumentasi lengkap struktur data per layer dari endpoint `/api/analyze`.

---

## Response Structure

```
{
  success:     Bool
  coordinates: { lat: Double, lng: Double }
  data:        [LayerResult]
}
```

### LayerResult (tiap item dalam `data`)

| Field             | Tipe   | Keterangan                                                        |
| ----------------- | ------ | ----------------------------------------------------------------- |
| `layer`           | String | Nama layer                                                        |
| `distance_meters` | Int    | Jarak dari titik koordinat ke zona. `0` = berada di dalam zona    |
| `label`           | String | Label human-readable hasil klasifikasi                            |
| `color`           | String | Hex color untuk UI (`#RRGGBB`)                                    |
| `attributes`      | Object | Data mentah dari database (berbeda tiap layer)                    |
| `total`           | Int    | Jumlah fasilitas dalam kategori. Hanya ada di `public_facilities` |

---

## Panduan Pengambilan Data per Layer (Frontend)

Referensi cepat field mana yang relevan untuk ditampilkan di UI.

| Layer               | Ambil dari                                 | Catatan                     |
| ------------------- | ------------------------------------------ | --------------------------- |
| `flood`             | `attributes.area`                          |                             |
| `temperature`       | `attributes.suhu`                          |                             |
| `air_quality`       | `label`                                    |                             |
| `green_spaces`      | `label`                                    |                             |
| `population`        | `attributes.jumlah_pen`                    |                             |
| `elevation`         | `label`                                    |                             |
| `roads_buffer`      | `distance_meters`, `label`                 | Muncul lebih dari satu item |
| `public_facilities` | `distance_meters`, `label`, `total`        | Muncul lebih dari satu item |
| `wifi`              | `attributes.dl_mbps`, `attributes.ul_mbps` |                             |
| `mobile_data`       | `attributes.dl_mbps`, `attributes.ul_mbps` |                             |
| `crime`             | `attributes.crime_total`                   |                             |

---

## Layer: `flood`

**Field klasifikasi:** `area` (String)

| Zone Value        | Label           | Color     |
| ----------------- | --------------- | --------- |
| `Low Flood Risk`  | Low Flood Risk  | `#34C759` |
| `High Flood Risk` | High Flood Risk | `#FF3B30` |
| _(lainnya)_       | Unknown         | `#8E8E93` |

**Attributes:**

| Field  | Tipe   | Keterangan       |
| ------ | ------ | ---------------- |
| `area` | String | Klasifikasi zona |

**Contoh:**

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

**Field klasifikasi:** `suhu` (String)

| Zone Value  | Label     | Color     |
| ----------- | --------- | --------- |
| `Very Cool` | Very Cool | `#00ff84` |
| `Cool`      | Cool      | `#00ff84` |
| `Moderate`  | Moderate  | `#FFCC00` |
| `Hot`       | Hot       | `#FF9500` |
| `Very Hot`  | Very Hot  | `#FF3B30` |
| _(lainnya)_ | Unknown   | `#8E8E93` |

**Attributes:**

| Field  | Tipe   | Keterangan       |
| ------ | ------ | ---------------- |
| `suhu` | String | Klasifikasi suhu |

**Contoh:**

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

**Field klasifikasi:** `polusi` (String)

| Zone Value  | Label    | Color     |
| ----------- | -------- | --------- |
| `Low`       | Good     | `#34C759` |
| `Medium`    | Moderate | `#FF9500` |
| `High`      | Bad      | `#FF3B30` |
| _(lainnya)_ | Unknown  | `#8E8E93` |

**Attributes:**

| Field        | Tipe   | Keterangan           |
| ------------ | ------ | -------------------- |
| `polusi`     | String | Klasifikasi polusi   |
| `objectid`   | Int    | ID objek di database |
| `shape_area` | Double | Luas area (derajat²) |
| `shape_leng` | Double | Panjang perimeter    |

**Contoh:**

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

**Field klasifikasi:** `rth` (String)

| Zone Value  | Label    | Color     |
| ----------- | -------- | --------- |
| `Dense`     | Dense    | `#34C759` |
| `Moderate`  | Moderate | `#FFCC00` |
| `Sparse`    | Sparse   | `#FF9500` |
| _(lainnya)_ | Unknown  | `#8E8E93` |

**Attributes:**

| Field      | Tipe   | Keterangan        |
| ---------- | ------ | ----------------- |
| `rth`      | String | Klasifikasi RTH   |
| `id`       | Int    | ID grid           |
| `gridcode` | Int    | Kode grid numerik |

**Contoh:**

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

**Field klasifikasi:** `jumlah_pen` (Double)

Tidak ada zone classification. Label menampilkan jumlah penduduk dengan format `{n} people`.

| Kondisi     | Color     |
| ----------- | --------- |
| Angka valid | `#5AC8FA` |
| Tidak valid | `#8E8E93` |

**Attributes (field utama):**

| Field        | Tipe   | Keterangan                           |
| ------------ | ------ | ------------------------------------ |
| `nama_kab`   | String | Nama kabupaten                       |
| `nama_kec`   | String | Nama kecamatan                       |
| `jumlah_pen` | Double | Total jumlah penduduk                |
| `jumlah_kk`  | Double | Jumlah kepala keluarga               |
| `pria`       | Double | Jumlah penduduk laki-laki            |
| `wanita`     | Double | Jumlah penduduk perempuan            |
| `islam`      | Double | Jumlah penduduk beragama Islam       |
| `hindu`      | Double | Jumlah penduduk beragama Hindu       |
| `kristen`    | Double | Jumlah penduduk beragama Kristen     |
| `katholik`   | Double | Jumlah penduduk beragama Katolik     |
| `budha`      | Double | Jumlah penduduk beragama Buddha      |
| `konghucu`   | Double | Jumlah penduduk beragama Konghucu    |
| `kawin`      | Double | Sudah menikah                        |
| `belum_kawi` | Double | Belum menikah                        |
| `cerai_hidu` | Double | Cerai hidup                          |
| `cerai_mati` | Double | Cerai mati                           |
| `tamat_sd`   | Double | Pendidikan tamat SD                  |
| `sltp`       | Double | Pendidikan tamat SLTP                |
| `slta`       | Double | Pendidikan tamat SLTA                |
| `d1_dan_d2`  | Double | Pendidikan D1/D2                     |
| `d3`         | Double | Pendidikan D3                        |
| `s1`         | Double | Pendidikan S1                        |
| `s2`         | Double | Pendidikan S2                        |
| `s3`         | Double | Pendidikan S3                        |
| `belum_tama` | Double | Belum tamat SD                       |
| `belum_tida` | Double | Tidak sekolah                        |
| `tidak_blm_` | Double | Tidak / belum sekolah                |
| `wiraswasta` | Double | Pekerjaan: wiraswasta                |
| `pelajar_ma` | Double | Pelajar / mahasiswa                  |
| `mengurus_r` | Double | Mengurus rumah tangga                |
| `pensiunan`  | Double | Pensiunan                            |
| `perdaganga` | Double | Pedagang                             |
| `guru`       | Double | Guru                                 |
| `perawat`    | Double | Perawat                              |
| `nelayan`    | Double | Nelayan                              |
| `pengacara`  | Double | Pengacara                            |
| `lainnya`    | Double | Pekerjaan lainnya                    |
| `u0`–`u75`   | Double | Distribusi usia per kelompok 5 tahun |

**Contoh:**

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

**Field klasifikasi:** `ketinggian` (String)

| Zone Value  | Label    | Color     |
| ----------- | -------- | --------- |
| `Lowland`   | Lowland  | `#FF9500` |
| `Midland`   | Midland  | `#34C759` |
| `Highland`  | Highland | `#5AC8FA` |
| _(lainnya)_ | Unknown  | `#8E8E93` |

**Attributes:**

| Field        | Tipe   | Keterangan             |
| ------------ | ------ | ---------------------- |
| `ketinggian` | String | Klasifikasi ketinggian |

**Contoh:**

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

**Field klasifikasi:** `remark` (String)

Tidak ada zone classification. Label mengikuti nilai `remark` langsung. Muncul lebih dari satu kali karena satu titik dapat masuk ke dalam beberapa buffer jalan sekaligus.

| Zone Value       | Label          | Color     |
| ---------------- | -------------- | --------- |
| `Collector Road` | Collector Road | `#8E8E93` |
| `Local Road`     | Local Road     | `#8E8E93` |
| `Other Road`     | Other Road     | `#8E8E93` |
| `Footpath`       | Footpath       | `#8E8E93` |
| _(lainnya)_      | Unknown        | `#8E8E93` |

**Attributes:**

| Field        | Tipe   | Keterangan                |
| ------------ | ------ | ------------------------- |
| `remark`     | String | Tipe jalan                |
| `objectid_1` | Int    | ID objek di database      |
| `shape_area` | Double | Luas buffer area (meter²) |
| `shape_leng` | Double | Panjang perimeter buffer  |

**Contoh:**

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

**Field klasifikasi:** `kategori` (String)

Muncul lebih dari satu kali, diurutkan dari yang terdekat. Setiap item mewakili satu kategori fasilitas. `total` menyatakan jumlah fasilitas dalam kategori tersebut dalam radius pencarian.

| Kategori contoh | Keterangan           |
| --------------- | -------------------- |
| `kesehatan`     | Fasilitas kesehatan  |
| `pendidikan`    | Fasilitas pendidikan |
| _(nilai lain)_  | Mengikuti data DB    |

**Attributes:**

| Field      | Tipe   | Keterangan         |
| ---------- | ------ | ------------------ |
| `kategori` | String | Kategori fasilitas |

**Field tambahan di root (bukan dalam attributes):**

| Field   | Tipe | Keterangan                          |
| ------- | ---- | ----------------------------------- |
| `total` | Int  | Jumlah fasilitas dalam kategori ini |

**Contoh:**

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

Tidak ada zone classification. Label menampilkan kecepatan download dan upload langsung.

| Kondisi       | Color     |
| ------------- | --------- |
| Data tersedia | `#5AC8FA` |

**Attributes:**

| Field        | Tipe   | Keterangan                      |
| ------------ | ------ | ------------------------------- |
| `dl_mbps`    | Double | Kecepatan download (Mbps)       |
| `ul_mbps`    | Double | Kecepatan upload (Mbps)         |
| `avg_lat_ms` | Int    | Rata-rata latency (ms)          |
| `avg_d_kbps` | Int    | Rata-rata download (Kbps)       |
| `avg_u_kbps` | Int    | Rata-rata upload (Kbps)         |
| `tests`      | Int    | Jumlah pengujian yang dilakukan |
| `devices`    | Int    | Jumlah perangkat yang diuji     |
| `quadkey`    | String | Kunci grid peta (Bing quadkey)  |

**Contoh:**

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

Struktur identik dengan `wifi`, namun mengukur kecepatan jaringan seluler.

**Attributes:**

| Field        | Tipe   | Keterangan                      |
| ------------ | ------ | ------------------------------- |
| `dl_mbps`    | Double | Kecepatan download (Mbps)       |
| `ul_mbps`    | Double | Kecepatan upload (Mbps)         |
| `avg_lat_ms` | Int    | Rata-rata latency (ms)          |
| `avg_d_kbps` | Int    | Rata-rata download (Kbps)       |
| `avg_u_kbps` | Int    | Rata-rata upload (Kbps)         |
| `tests`      | Int    | Jumlah pengujian yang dilakukan |
| `devices`    | Int    | Jumlah perangkat yang diuji     |
| `quadkey`    | String | Kunci grid peta (Bing quadkey)  |

**Contoh:**

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

Tidak ada zone classification. Label menampilkan total kasus kriminal.

| Kondisi       | Color     |
| ------------- | --------- |
| Data tersedia | `#FF9500` |

**Attributes:**

| Field            | Tipe   | Keterangan                                |
| ---------------- | ------ | ----------------------------------------- |
| `crime_total`    | Int    | Total kasus kriminal                      |
| `crime_cleared`  | Int    | Jumlah kasus yang diselesaikan            |
| `clearance_rate` | Double | Persentase kasus yang diselesaikan (%)    |
| `crime_rate`     | Double | Tingkat kriminalitas per 100.000 penduduk |
| `tahun`          | Int    | Tahun data                                |
| `nama_kab`       | String | Nama kabupaten                            |
| `jumlah_pen`     | Double | Jumlah penduduk kabupaten                 |
| `jumlah_kk`      | Double | Jumlah kepala keluarga kabupaten          |
| `sumber`         | String | Sumber data                               |

**Contoh:**

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

## Catatan Multiplicity

| Layer               | Kemunculan   | Alasan                                      |
| ------------------- | ------------ | ------------------------------------------- |
| `flood`             | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `temperature`       | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `air_quality`       | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `green_spaces`      | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `population`        | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `elevation`         | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `wifi`              | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `mobile_data`       | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `crime`             | Maks. 1 kali | `ST_Intersects` dengan `LIMIT 1`            |
| `roads_buffer`      | Lebih dari 1 | Satu titik bisa masuk beberapa buffer jalan |
| `public_facilities` | Lebih dari 1 | Radius search per kategori fasilitas        |
