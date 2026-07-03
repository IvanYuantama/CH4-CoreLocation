//
//  CacheKey.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import MapKit

/// Membuat cache key dari kombinasi LayerKey + bbox.
/// Bbox dibulatkan ke 2 desimal agar scroll kecil tetap kena cache hit.
struct CacheKey {
    let value: String

    init(layerKey: LayerKey, region: MKCoordinateRegion) {
        self.value = "\(layerKey.rawValue)_\(region.toBboxCacheKey())"
    }

    init(layerKey: LayerKey, bboxString: String) {
        // Ambil 2 desimal dari komponen bbox yang sudah ada
        self.value = "\(layerKey.rawValue)_\(bboxString)"
    }
}
