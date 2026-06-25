const express = require("express");
const router = express.Router();
const db = require("../db/db.js");

/**
 * Konfigurasi warna dan label per layer untuk MapKit iOS
 *
 * Setiap zone punya:
 *  - color : hex fill polygon
 *  - label : teks yang ditampilkan ke user
 *  - risk  : "low" | "medium" | "high" (bisa dipakai app untuk ikon / alert)
 */
const LAYER_CONFIG = {
  flood: {
    field: "area",
    zones: {
      "Low Flood Risk": {
        color: "#34C759",
        label: "Risiko Banjir Rendah",
        risk: "low",
      },
      "Medium Flood Risk": {
        color: "#FF9500",
        label: "Risiko Banjir Sedang",
        risk: "medium",
      },
      "High Flood Risk": {
        color: "#FF3B30",
        label: "Risiko Banjir Tinggi",
        risk: "high",
      },
    },
    defaultZone: {
      color: "#8E8E93",
      label: "Tidak Diketahui",
      risk: "unknown",
    },
  },

  temperature: {
    field: "suhu",
    zones: {
      Cool: { color: "#5AC8FA", label: "Suhu Sejuk", risk: "low" },
      Warm: { color: "#FFCC00", label: "Suhu Hangat", risk: "medium" },
      Hot: { color: "#FF9500", label: "Suhu Panas", risk: "medium" },
      "Very Hot": {
        color: "#FF3B30",
        label: "Suhu Sangat Panas",
        risk: "high",
      },
    },
    defaultZone: {
      color: "#8E8E93",
      label: "Tidak Diketahui",
      risk: "unknown",
    },
  },

  air_quality: {
    field: "polusi",
    zones: {
      Low: { color: "#34C759", label: "Kualitas Udara Baik", risk: "low" },
      Medium: {
        color: "#FF9500",
        label: "Kualitas Udara Sedang",
        risk: "medium",
      },
      High: { color: "#FF3B30", label: "Kualitas Udara Buruk", risk: "high" },
    },
    defaultZone: {
      color: "#8E8E93",
      label: "Tidak Diketahui",
      risk: "unknown",
    },
  },

  green_spaces: {
    field: "type", // sesuaikan dengan kolom aktual tabel green_spaces
    zones: {
      Park: { color: "#34C759", label: "Taman / RTH", risk: "low" },
      Forest: { color: "#30D158", label: "Hutan Kota", risk: "low" },
      "Sports Field": {
        color: "#5AC8FA",
        label: "Lapangan Olahraga",
        risk: "low",
      },
    },
    defaultZone: {
      color: "#30D158",
      label: "Ruang Terbuka Hijau",
      risk: "low",
    },
  },

  public_facilities: {
    field: "facility_type", // sesuaikan dengan kolom aktual tabel public_facilities
    zones: {
      Hospital: { color: "#FF3B30", label: "Rumah Sakit", risk: "low" },
      School: { color: "#007AFF", label: "Sekolah", risk: "low" },
      Government: { color: "#5856D6", label: "Kantor Pemerintah", risk: "low" },
      Market: { color: "#FF9500", label: "Pasar", risk: "low" },
    },
    defaultZone: { color: "#007AFF", label: "Fasilitas Umum", risk: "low" },
  },

  population: {
    field: "density_category", // sesuaikan dengan kolom aktual tabel population_data
    zones: {
      Low: { color: "#5AC8FA", label: "Kepadatan Rendah", risk: "low" },
      Medium: { color: "#FFCC00", label: "Kepadatan Sedang", risk: "medium" },
      High: { color: "#FF9500", label: "Kepadatan Tinggi", risk: "medium" },
      "Very High": {
        color: "#FF3B30",
        label: "Kepadatan Sangat Tinggi",
        risk: "high",
      },
    },
    defaultZone: {
      color: "#8E8E93",
      label: "Tidak Diketahui",
      risk: "unknown",
    },
  },

  elevation: {
    field: "elevation_category", // sesuaikan dengan kolom aktual tabel elevation_zones
    zones: {
      Low: { color: "#FF9500", label: "Dataran Rendah", risk: "medium" },
      Medium: { color: "#FFCC00", label: "Dataran Sedang", risk: "low" },
      High: { color: "#34C759", label: "Dataran Tinggi", risk: "low" },
      "Very High": { color: "#5AC8FA", label: "Pegunungan", risk: "low" },
    },
    defaultZone: {
      color: "#8E8E93",
      label: "Tidak Diketahui",
      risk: "unknown",
    },
  },

  roads_buffer: {
    field: "road_type", // sesuaikan dengan kolom aktual tabel roads_buffer
    zones: {
      Primary: {
        color: "#FF3B30",
        label: "Jalan Primer (Buffer)",
        risk: "low",
      },
      Secondary: {
        color: "#FF9500",
        label: "Jalan Sekunder (Buffer)",
        risk: "low",
      },
      Residential: {
        color: "#FFCC00",
        label: "Jalan Lingkungan (Buffer)",
        risk: "low",
      },
    },
    defaultZone: { color: "#8E8E93", label: "Buffer Jalan", risk: "low" },
  },
};

// -------------------------------------------------------------------
// Helper: ambil metadata warna dari konfigurasi di atas
// -------------------------------------------------------------------
function getZoneMeta(layerKey, fieldValue) {
  const cfg = LAYER_CONFIG[layerKey];
  if (!cfg)
    return {
      color: "#8E8E93",
      label: fieldValue || "Tidak Diketahui",
      risk: "unknown",
    };
  return (
    cfg.zones[fieldValue] || {
      ...cfg.defaultZone,
      label: fieldValue || cfg.defaultZone.label,
    }
  );
}

// -------------------------------------------------------------------
// Helper: bangun satu sub-query untuk mengambil GeoJSON per tabel
// -------------------------------------------------------------------
function buildLayerQuery(tableName, layerKey, classField, params) {
  // params sudah berisi [lng, lat] atau array yang akan di-spread
  return `
    SELECT
      '${layerKey}'                            AS layer,
      ${classField}                            AS zone_value,
      ST_AsGeoJSON(wkb_geometry)::json         AS geometry
    FROM ${tableName}
  `;
}

// -------------------------------------------------------------------
// GET /api/map/layers
// Mengembalikan semua polygon semua layer dalam format GeoJSON
// siap dikonsumsi MapKit JS / Swift MKGeoJSONDecoder
//
// Query params (opsional):
//   ?layers=flood,temperature   → hanya layer tertentu
//   ?bbox=west,south,east,north → filter bounding box
// -------------------------------------------------------------------
router.get("/layers", async (req, res) => {
  try {
    const requestedLayers = req.query.layers
      ? req.query.layers.split(",").map((l) => l.trim())
      : null;

    // Bbox opsional: ?bbox=115.1,−8.8,115.3,−8.6
    let bboxClause = "";
    let bboxParams = [];
    if (req.query.bbox) {
      const parts = req.query.bbox.split(",").map(Number);
      if (parts.length === 4 && parts.every((n) => !isNaN(n))) {
        const [west, south, east, north] = parts;
        bboxClause = `
          WHERE wkb_geometry &&
            ST_MakeEnvelope($1, $2, $3, $4, 4326)
        `;
        bboxParams = [west, south, east, north];
      }
    }

    // Definisi tabel → layer key → kolom klasifikasi
    const tables = [
      { table: "flood_zones", key: "flood", field: "area" },
      { table: "temperature_zones", key: "temperature", field: "suhu" },
      { table: "air_quality", key: "air_quality", field: "polusi" },
      { table: "green_spaces", key: "green_spaces", field: "type" },
      {
        table: "public_facilities",
        key: "public_facilities",
        field: "facility_type",
      },
      {
        table: "population_data",
        key: "population",
        field: "density_category",
      },
      {
        table: "elevation_zones",
        key: "elevation",
        field: "elevation_category",
      },
      { table: "roads_buffer", key: "roads_buffer", field: "road_type" },
    ];

    const featureCollections = {};

    await Promise.all(
      tables
        .filter((t) => !requestedLayers || requestedLayers.includes(t.key))
        .map(async (t) => {
          const sql = `
            SELECT
              ${t.field}                                AS zone_value,
              ST_AsGeoJSON(
                ST_SimplifyPreserveTopology(wkb_geometry, 0.0001)
              )::json                                   AS geometry
            FROM ${t.table}
            ${bboxClause}
          `;

          const result = await db.query(sql, bboxParams);

          // Bangun GeoJSON FeatureCollection
          const features = result.rows.map((row) => {
            const meta = getZoneMeta(t.key, row.zone_value);
            return {
              type: "Feature",
              geometry: row.geometry,
              properties: {
                layer: t.key,
                zone_value: row.zone_value,
                label: meta.label,
                color: meta.color, // hex, langsung pakai di Swift
                risk: meta.risk,
              },
            };
          });

          featureCollections[t.key] = {
            type: "FeatureCollection",
            features,
          };
        }),
    );

    res.json({
      success: true,
      layers: featureCollections,
    });
  } catch (err) {
    console.error("[/map/layers]", err);
    res.status(500).json({ error: err.message });
  }
});

// -------------------------------------------------------------------
// GET /api/map/layers/:layerKey
// Ambil satu layer saja → lebih ringan untuk lazy loading di iOS
//
// Contoh: GET /api/map/layers/flood
// -------------------------------------------------------------------
router.get("/layers/:layerKey", async (req, res) => {
  const { layerKey } = req.params;

  const tableMap = {
    flood: { table: "flood_zones", field: "area" },
    temperature: { table: "temperature_zones", field: "suhu" },
    air_quality: { table: "air_quality", field: "polusi" },
    green_spaces: { table: "green_spaces", field: "type" },
    public_facilities: { table: "public_facilities", field: "facility_type" },
    population: { table: "population_data", field: "density_category" },
    elevation: { table: "elevation_zones", field: "elevation_category" },
    roads_buffer: { table: "roads_buffer", field: "road_type" },
  };

  const def = tableMap[layerKey];
  if (!def) {
    return res.status(404).json({
      error: `Layer '${layerKey}' tidak ditemukan.`,
      available: Object.keys(tableMap),
    });
  }

  try {
    let bboxClause = "";
    let bboxParams = [];
    if (req.query.bbox) {
      const parts = req.query.bbox.split(",").map(Number);
      if (parts.length === 4 && parts.every((n) => !isNaN(n))) {
        const [west, south, east, north] = parts;
        bboxClause = `WHERE wkb_geometry && ST_MakeEnvelope($1, $2, $3, $4, 4326)`;
        bboxParams = [west, south, east, north];
      }
    }

    const sql = `
      SELECT
        ${def.field}                                    AS zone_value,
        ST_AsGeoJSON(
          ST_SimplifyPreserveTopology(wkb_geometry, 0.0001)
        )::json                                         AS geometry
      FROM ${def.table}
      ${bboxClause}
    `;

    const result = await db.query(sql, bboxParams);

    const features = result.rows.map((row) => {
      const meta = getZoneMeta(layerKey, row.zone_value);
      return {
        type: "Feature",
        geometry: row.geometry,
        properties: {
          layer: layerKey,
          zone_value: row.zone_value,
          label: meta.label,
          color: meta.color,
          risk: meta.risk,
        },
      };
    });

    res.json({
      success: true,
      layer: layerKey,
      type: "FeatureCollection",
      features,
    });
  } catch (err) {
    console.error(`[/map/layers/${layerKey}]`, err);
    res.status(500).json({ error: err.message });
  }
});

// -------------------------------------------------------------------
// GET /api/map/layers/legend
// Kembalikan seluruh konfigurasi warna/label untuk UI legenda di iOS
// -------------------------------------------------------------------
router.get("/legend", async (req, res) => {
  const legend = {};
  for (const [key, cfg] of Object.entries(LAYER_CONFIG)) {
    legend[key] = {
      zones: Object.entries(cfg.zones).map(([zoneValue, meta]) => ({
        zone_value: zoneValue,
        label: meta.label,
        color: meta.color,
        risk: meta.risk,
      })),
      default: cfg.defaultZone,
    };
  }
  res.json({ success: true, legend });
});

module.exports = router;
