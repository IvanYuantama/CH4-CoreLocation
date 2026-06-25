const express = require("express");
const router = express.Router();
const db = require("../db/db.js");

// Query semua layer berdasarkan satu titik koordinat
// GET /api/property/analyze?lat=-8.6500&lng=115.2167
router.get("/analyze", async (req, res) => {
  const { lat, lng } = req.query;

  if (!lat || !lng) {
    return res.status(400).json({ error: "lat dan lng wajib diisi" });
  }

  try {
    const point = `ST_SetSRID(ST_Point(${lng}, ${lat}), 4326)`;

    const query = `
      SELECT * FROM (

        -- Banjir
        SELECT 'flood' AS layer,
               ST_Distance(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography) AS distance_meters,
               row_to_json(f) AS data
        FROM flood_zones f
        WHERE ST_DWithin(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 5000)
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Suhu
        SELECT 'temperature' AS layer,
               ST_Distance(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography) AS distance_meters,
               row_to_json(t) AS data
        FROM temperature_zones t
        WHERE ST_DWithin(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 5000)
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Polusi Udara
        SELECT 'air_quality' AS layer,
               ST_Distance(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography) AS distance_meters,
               row_to_json(a) AS data
        FROM air_quality a
        WHERE ST_DWithin(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 5000)
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- RTH
        SELECT 'green_spaces' AS layer,
               ST_Distance(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography) AS distance_meters,
               row_to_json(g) AS data
        FROM green_spaces g
        WHERE ST_DWithin(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 5000)
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Fasilitas Umum
        SELECT 'public_facilities' AS layer,
               ST_Distance(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography) AS distance_meters,
               row_to_json(p) AS data
        FROM public_facilities p
        WHERE ST_DWithin(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 5000)
        ORDER BY distance_meters LIMIT 1

        UNION ALL

        -- Populasi
        SELECT 'population' AS layer,
               ST_Distance(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography) AS distance_meters,
               row_to_json(pop) AS data
        FROM population_data pop
        WHERE ST_DWithin(wkb_geometry::geography, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 5000)
        ORDER BY distance_meters LIMIT 1

      ) results
      ORDER BY layer
    `;

    const result = await db.query(query, [lng, lat]);

    res.json({
      success: true,
      coordinates: { lat: parseFloat(lat), lng: parseFloat(lng) },
      layers: result.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
