const express = require("express");
const router = express.Router();
const db = require("../db/db.js");

// -------------------------------------------------------------------
// Reuse konfigurasi yang sama dengan mapLayersController
// sehingga warna & label selalu konsisten di seluruh app
// -------------------------------------------------------------------
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
    field: "type",
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
    field: "facility_type",
    zones: {
      Hospital: { color: "#FF3B30", label: "Rumah Sakit", risk: "low" },
      School: { color: "#007AFF", label: "Sekolah", risk: "low" },
      Government: { color: "#5856D6", label: "Kantor Pemerintah", risk: "low" },
      Market: { color: "#FF9500", label: "Pasar", risk: "low" },
    },
    defaultZone: { color: "#007AFF", label: "Fasilitas Umum", risk: "low" },
  },

  population: {
    field: "density_category",
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
    field: "elevation_category",
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
    field: "road_type",
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
// Helper: ambil metadata warna/label dari konfigurasi
// -------------------------------------------------------------------
function getZoneMeta(layerKey, zoneValue) {
  const cfg = LAYER_CONFIG[layerKey];
  if (!cfg)
    return {
      color: "#8E8E93",
      label: zoneValue || "Tidak Diketahui",
      risk: "unknown",
    };
  return (
    cfg.zones[zoneValue] || {
      ...cfg.defaultZone,
      label: zoneValue || cfg.defaultZone.label,
    }
  );
}

// -------------------------------------------------------------------
// Helper: ekstrak zone_value dari row.data berdasarkan field config
// -------------------------------------------------------------------
function extractZoneValue(layerKey, data) {
  const cfg = LAYER_CONFIG[layerKey];
  if (!cfg || !data) return null;
  return data[cfg.field] ?? null;
}

// -------------------------------------------------------------------
// GET /api/property/analyze?lat=-8.6500&lng=115.2167
//
// Perubahan dari versi lama:
//  + Ditambah layer elevation_zones dan roads_buffer
//  + Setiap layer kini menyertakan: zone_value, label, color, risk
//  + Summary keseluruhan risiko properti (overall_risk)
// -------------------------------------------------------------------
router.get("/analyze", async (req, res) => {
  const { lat, lng } = req.query;

  if (!lat || !lng) {
    return res.status(400).json({ error: "lat dan lng wajib diisi" });
  }

  try {
    // Radius pencarian dalam meter
    const RADIUS = 5000;

    const query = `
      SELECT * FROM (

        -- Banjir
        SELECT 'flood' AS layer,
               area    AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(f) AS data
        FROM flood_zones f
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Suhu
        SELECT 'temperature' AS layer,
               suhu          AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(t) AS data
        FROM temperature_zones t
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Kualitas Udara
        SELECT 'air_quality' AS layer,
               polusi         AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(a) AS data
        FROM air_quality a
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- RTH / Green Spaces
        SELECT 'green_spaces' AS layer,
               type            AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(g) AS data
        FROM green_spaces g
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Fasilitas Umum
        SELECT 'public_facilities' AS layer,
               facility_type        AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(p) AS data
        FROM public_facilities p
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Populasi
        SELECT 'population'      AS layer,
               density_category   AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(pop) AS data
        FROM population_data pop
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Elevasi (baru)
        SELECT 'elevation'          AS layer,
               elevation_category    AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(e) AS data
        FROM elevation_zones e
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Buffer Jalan (baru)
        SELECT 'roads_buffer' AS layer,
               road_type       AS zone_value,
               ST_Distance(
                 wkb_geometry::geography,
                 ST_SetSRID(ST_Point($1, $2), 4326)::geography
               ) AS distance_meters,
               row_to_json(r) AS data
        FROM roads_buffer r
        WHERE ST_DWithin(
          wkb_geometry::geography,
          ST_SetSRID(ST_Point($1, $2), 4326)::geography,
          ${RADIUS}
        )
        ORDER BY distance_meters LIMIT 1

      ) results
      ORDER BY layer
    `;

    const result = await db.query(query, [lng, lat]);

    // -------------------------------------------------------------------
    // Enrichment: tambahkan color, label, risk ke setiap baris
    // -------------------------------------------------------------------
    const RISK_WEIGHT = { high: 3, medium: 2, low: 1, unknown: 0 };

    const layers = result.rows.map((row) => {
      // zone_value sudah diambil langsung di SELECT, tapi fallback ke data juga
      const zoneValue = row.zone_value ?? extractZoneValue(row.layer, row.data);
      const meta = getZoneMeta(row.layer, zoneValue);

      return {
        layer: row.layer,
        distance_meters: Math.round(row.distance_meters),
        zone_value: zoneValue,
        label: meta.label,
        color: meta.color,
        risk: meta.risk,
        data: row.data,
      };
    });

    // -------------------------------------------------------------------
    // Overall risk: ambil risk tertinggi dari semua layer
    // -------------------------------------------------------------------
    const overallRisk = layers.reduce((worst, l) => {
      return (RISK_WEIGHT[l.risk] ?? 0) > (RISK_WEIGHT[worst] ?? 0)
        ? l.risk
        : worst;
    }, "low");

    // Ringkasan per layer untuk ditampilkan sebagai badge / card di iOS
    const summary = layers.map((l) => ({
      layer: l.layer,
      label: l.label,
      color: l.color,
      risk: l.risk,
    }));

    res.json({
      success: true,
      coordinates: {
        lat: parseFloat(lat),
        lng: parseFloat(lng),
      },
      overall_risk: overallRisk, // "low" | "medium" | "high" | "unknown"
      summary, // array ringkas untuk card UI
      layers, // detail lengkap tiap layer
    });
  } catch (err) {
    console.error("[/property/analyze]", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
