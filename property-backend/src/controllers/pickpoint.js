const express = require("express");
const router = express.Router();
const db = require("../db/db.js");

// -------------------------------------------------------------------
// Config for json output
// -------------------------------------------------------------------

const LAYER_CONFIG = {
  flood: {
    field: "area",
    zones: {
      "Low Flood Risk": { color: "#34C759", label: "Low Flood Risk" },
      "High Flood Risk": { color: "#FF3B30", label: "High Flood Risk" },
    },
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  temperature: {
    field: "suhu",
    zones: {
      Cool: { color: "#00ff84", label: "Cool" },
      Moderate: { color: "#FFCC00", label: "Moderate" },
      Hot: { color: "#FF9500", label: "Hot" },
      "Very Hot": { color: "#FF3B30", label: "Very Hot" },
      "Very Cool": { color: "#00ff84", label: "Very Cool" },
    },
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  air_quality: {
    field: "polusi",
    zones: {
      Low: { color: "#34C759", label: "Good" },
      Medium: { color: "#FF9500", label: "Moderate" },
      High: { color: "#FF3B30", label: "Bad" },
    },
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  green_spaces: {
    field: "rth",
    zones: {
      Dense: { color: "#34C759", label: "Dense" },
      Moderate: { color: "#FFCC00", label: "Moderate" },
      Sparse: { color: "#FF9500", label: "Sparse" },
    },
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  public_facilities: {
    field: "kategori",
    zones: {},
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  population: {
    field: "jumlah_pen",
    zones: {},
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  elevation: {
    field: "ketinggian",
    zones: {},
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  roads_buffer: {
    field: "remark",
    zones: {},
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
  // Wifi - tampilkan nilai dl & ul apa adanya
  wifi: {
    field: "dl_mbps",
    zones: {},
    defaultZone: { color: "#5AC8FA", label: "Unknown" },
  },
  // Mobile data - tampilkan nilai dl & ul apa adanya
  mobile_data: {
    field: "dl_mbps",
    zones: {},
    defaultZone: { color: "#5AC8FA", label: "Unknown" },
  },
  // Crime - tampilkan crime_total apa adanya
  crime: {
    field: "crime_total",
    zones: {},
    defaultZone: { color: "#8E8E93", label: "Unknown" },
  },
};

// -------------------------------------------------------------------
// Categorization for numeric column
// -------------------------------------------------------------------
function categorizePopulation(jumlah) {
  const n = parseFloat(jumlah);
  if (isNaN(n)) return { color: "#8E8E93", label: "Unknown" };
  return { color: "#5AC8FA", label: String(Math.round(n)) + " people" };
}

function categorizeElevation(ketinggian) {
  const map = {
    Lowland: { color: "#FF9500", label: "Lowland" },
    Midland: { color: "#34C759", label: "Midland" },
    Highland: { color: "#5AC8FA", label: "Highland" },
  };
  return (
    map[ketinggian] ?? { color: "#8E8E93", label: ketinggian ?? "Unknown" }
  );
}

function categorizeWifi(val) {
  const [dl, ul] = (val || "").split("|").map(parseFloat);
  if (isNaN(dl) && isNaN(ul)) return { color: "#5AC8FA", label: "Unknown" };
  const dlStr = isNaN(dl) ? "-" : `${dl.toFixed(1)} Mbps`;
  const ulStr = isNaN(ul) ? "-" : `${ul.toFixed(1)} Mbps`;
  return {
    color: "#5AC8FA",
    label: `Download ${dlStr}, Upload ${ulStr}`,
  };
}

function categorizeMobileData(val) {
  const [dl, ul] = (val || "").split("|").map(parseFloat);
  if (isNaN(dl) && isNaN(ul)) return { color: "#5AC8FA", label: "Unknown" };
  const dlStr = isNaN(dl) ? "-" : `${dl.toFixed(1)} Mbps`;
  const ulStr = isNaN(ul) ? "-" : `${ul.toFixed(1)} Mbps`;
  return {
    color: "#5AC8FA",
    label: `Download ${dlStr}, Upload ${ulStr}`,
  };
}

function categorizeCrime(val) {
  const n = parseFloat(val);
  if (isNaN(n)) return { color: "#8E8E93", label: "Unknown" };
  return {
    color: "#FF9500",
    label: `${Math.round(n)} cases`,
  };
}

// -------------------------------------------------------------------
// Helper SQL: For MapKit render
// -------------------------------------------------------------------
function buildPropertiesSql(layerKey, field) {
  const cfg = LAYER_CONFIG[layerKey];
  if (!cfg) {
    return `jsonb_build_object('layer', '${layerKey}', 'zone_value', ${field}, 'color', '#8E8E93', 'label', COALESCE(${field}::text, 'Unknown'))`;
  }

  const zoneEntries = Object.entries(cfg.zones || {});

  if (zoneEntries.length === 0) {
    return `jsonb_build_object(
      'layer', '${layerKey}',
      'zone_value', ${field},
      'color', '${cfg.defaultZone.color}',
      'label', COALESCE(${field}::text, '${cfg.defaultZone.label}')
    )`;
  }

  let colorCase = `CASE ${field}::text `;
  let labelCase = `CASE ${field}::text `;

  for (const [zVal, meta] of zoneEntries) {
    const safeVal = zVal.replace(/'/g, "''");
    colorCase += `WHEN '${safeVal}' THEN '${meta.color}' `;
    labelCase += `WHEN '${safeVal}' THEN '${meta.label}' `;
  }

  colorCase += `ELSE '${cfg.defaultZone.color}' END`;
  labelCase += `ELSE COALESCE(${field}::text, '${cfg.defaultZone.label}') END`;

  return `jsonb_build_object(
    'layer', '${layerKey}',
    'zone_value', ${field},
    'color', ${colorCase},
    'label', ${labelCase}
  )`;
}

// -------------------------------------------------------------------
// Helper: take metadata color/label
// -------------------------------------------------------------------
function getZoneMeta(layerKey, zoneValue) {
  if (layerKey === "population") return categorizePopulation(zoneValue);
  if (layerKey === "elevation") return categorizeElevation(zoneValue);
  if (layerKey === "wifi") return categorizeWifi(zoneValue);
  if (layerKey === "mobile_data") return categorizeMobileData(zoneValue);
  if (layerKey === "crime") return categorizeCrime(zoneValue);

  const cfg = LAYER_CONFIG[layerKey];
  if (!cfg) return { color: "#8E8E93", label: zoneValue || "Unknown" };

  return (
    cfg.zones[zoneValue] || {
      ...cfg.defaultZone,
      label: zoneValue || cfg.defaultZone.label,
    }
  );
}

// -------------------------------------------------------------------
// GET /api/analyze?lat=-8.6500&lng=115.2167
// -------------------------------------------------------------------
const RADIUS_DEG = 0.027; // ≈ 3km

router.get("/analyze", async (req, res) => {
  const { lat, lng } = req.query;

  if (!lat || !lng)
    return res.status(400).json({ error: "lat dan lng wajib diisi" });

  const latNum = parseFloat(lat);
  const lngNum = parseFloat(lng);

  if (isNaN(latNum) || isNaN(lngNum))
    return res.status(400).json({ error: "lat dan lng harus berupa angka" });

  try {
    const queriesConfig = [
      {
        table: "flood_zones",
        layer: "flood",
        valCol: "area",
        searchType: "intersect",
      },
      {
        table: "temperature_zones",
        layer: "temperature",
        valCol: "suhu",
        searchType: "intersect",
      },
      {
        table: "air_quality",
        layer: "air_quality",
        valCol: "polusi",
        searchType: "intersect",
      },
      {
        table: "green_spaces",
        layer: "green_spaces",
        valCol: "rth",
        searchType: "intersect",
      },
      {
        table: "population_data",
        layer: "population",
        valCol: "jumlah_pen::text",
        searchType: "intersect",
      },
      {
        table: "elevation_zones",
        layer: "elevation",
        valCol: "ketinggian::text",
        searchType: "intersect",
      },
      {
        table: "roads_buffer",
        layer: "roads_buffer",
        valCol: "remark",
        searchType: "radius",
      },
      {
        table: "public_facilities",
        layer: "public_facilities",
        valCol: "kategori",
        searchType: "grouped",
      },
      {
        table: "wifi_zones",
        layer: "wifi",
        valCol: "(dl_mbps::text || '|' || ul_mbps::text)",
        searchType: "intersect",
      },
      {
        table: "mobile_data_zones",
        layer: "mobile_data",
        valCol: "(dl_mbps::text || '|' || ul_mbps::text)",
        searchType: "intersect",
      },
      {
        table: "crime_zones",
        layer: "crime",
        valCol: "crime_total::text",
        searchType: "intersect",
      },
    ];

    const promises = queriesConfig.map(async (cfg) => {
      let query = "";

      if (cfg.searchType === "intersect") {
        query = `
          SELECT $3::text AS layer,
                 ${cfg.valCol} AS zone_value,
                 0 AS distance_meters,
                 to_jsonb(t) - 'wkb_geometry' - 'ogc_fid' AS data
          FROM ${cfg.table} t
          WHERE ST_Intersects(wkb_geometry, ST_SetSRID(ST_Point($1, $2), 4326))
          LIMIT 1
        `;
        const result = await db.query(query, [lngNum, latNum, cfg.layer]);
        return result.rows[0];
      } else if (cfg.searchType === "grouped") {
        query = `
          SELECT
            $3::text AS layer,
            ${cfg.valCol} AS zone_value,
            MAX(ST_Distance(wkb_geometry, ST_SetSRID(ST_Point($1, $2), 4326)) * 111320) AS distance_meters,
            COUNT(*) AS total,
            jsonb_build_object('kategori', ${cfg.valCol}) AS data
          FROM ${cfg.table} t
          WHERE ST_DWithin(wkb_geometry, ST_SetSRID(ST_Point($1, $2), 4326), ${RADIUS_DEG})
          GROUP BY ${cfg.valCol}
          ORDER BY distance_meters ASC
        `;
        const result = await db.query(query, [lngNum, latNum, cfg.layer]);
        return result.rows;
      } else {
        query = `
          SELECT $3::text AS layer,
                 ${cfg.valCol} AS zone_value,
                 ST_Distance(wkb_geometry, ST_SetSRID(ST_Point($1, $2), 4326)) * 111320 AS distance_meters,
                 to_jsonb(t) - 'wkb_geometry' - 'ogc_fid' AS data
          FROM ${cfg.table} t
          WHERE ST_DWithin(wkb_geometry, ST_SetSRID(ST_Point($1, $2), 4326), ${RADIUS_DEG})
          ORDER BY wkb_geometry <-> ST_SetSRID(ST_Point($1, $2), 4326)
          LIMIT 5
        `;
        const result = await db.query(query, [lngNum, latNum, cfg.layer]);
        return result.rows;
      }
    });

    const resultsRaw = await Promise.all(promises);
    const validResults = resultsRaw
      .flat()
      .filter((r) => r !== undefined && r !== null);

    const finalData = validResults.map((row) => {
      const meta = getZoneMeta(row.layer, row.zone_value);
      const item = {
        layer: row.layer,
        distance_meters: Math.round(row.distance_meters),
        label: meta.label,
        color: meta.color,
        attributes: row.data,
      };
      if (row.total !== undefined) item.total = parseInt(row.total);
      return item;
    });

    res.json({
      success: true,
      coordinates: { lat: latNum, lng: lngNum },
      data: finalData,
    });
  } catch (err) {
    console.error("[/analyze]", err);
    res.status(500).json({ error: err.message });
  }
});

// -------------------------------------------------------------------
// GET /api/layers/:layerKey?bbox=minLng,minLat,maxLng,maxLat
// For MapKit rendering polygon layer with BBOX
// -------------------------------------------------------------------
router.get("/layers/:layerKey", async (req, res) => {
  const { layerKey } = req.params;

  if (!req.query.bbox) {
    return res.status(400).json({
      error: "Parameter ?bbox=minLng,minLat,maxLng,maxLat must be filled!",
    });
  }

  const parts = req.query.bbox.split(",").map(Number);
  if (parts.length !== 4 || parts.some(isNaN)) {
    return res.status(400).json({
      error: "Not valid. Use this: minLng,minLat,maxLng,maxLat",
    });
  }

  const tableMap = {
    flood: { table: "flood_zones", field: "area" },
    temperature: { table: "temperature_zones", field: "suhu" },
    air_quality: { table: "air_quality", field: "polusi" },
    green_spaces: { table: "green_spaces", field: "rth" },
    population: { table: "population_data", field: "jumlah_pen" },
    elevation: { table: "elevation_zones", field: "ketinggian" },
    roads_buffer: { table: "roads_buffer", field: "remark" },
    public_facilities: { table: "public_facilities", field: "kategori" },
    wifi: { table: "wifi_zones", field: "dl_mbps" },
    mobile_data: { table: "mobile_data_zones", field: "dl_mbps" },
    crime: { table: "crime_zones", field: "crime_total" },
  };

  const def = tableMap[layerKey];
  if (!def) {
    return res.status(404).json({
      error: `Layer '${layerKey}' not found.`,
      available: Object.keys(tableMap),
    });
  }

  try {
    const [west, south, east, north] = parts;

    const sql = `
      SELECT jsonb_build_object(
        'type', 'FeatureCollection',
        'features', COALESCE(jsonb_agg(
          jsonb_build_object(
            'type', 'Feature',
            'geometry', ST_AsGeoJSON(ST_SimplifyPreserveTopology(wkb_geometry, 0.0001))::json,
            'properties', ${buildPropertiesSql(layerKey, def.field)}
          )
        ), '[]'::jsonb)
      ) AS geojson_data
      FROM ${def.table}
      WHERE wkb_geometry && ST_MakeEnvelope($1, $2, $3, $4, 4326)
    `;

    const result = await db.query(sql, [west, south, east, north]);

    res.json({
      success: true,
      layer: layerKey,
      ...result.rows[0].geojson_data,
    });
  } catch (err) {
    console.error(`[/layers/${layerKey}]`, err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
