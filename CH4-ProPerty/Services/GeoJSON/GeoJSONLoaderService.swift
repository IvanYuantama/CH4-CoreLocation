//
//  GeoJSONLoaderService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

//  Fetch + decode GeoJSON layer dari backend.
//  Pakai MKGeoJSONDecoder (MapKit native) agar bisa langsung addOverlay ke MKMapView.
//  Cek cache dulu sebelum hit network.
//

import Foundation
import MapKit

final class GeoJSONLoaderService {

    static let shared = GeoJSONLoaderService()

    private let api   = LocationAnalysisAPIService.shared
    private let cache = GeoJSONCacheService.shared

    private init() {}

    /// Fetch GeoJSON untuk satu layer.
    /// Return (data mentah, decoded MKGeoJSONObject array)
    /// Data mentah disimpan ke cache; decoded object dipakai GeoJSONOverlayManager.
    func load(
        layer: LayerKey,
        region: MKCoordinateRegion
    ) async throws -> (data: Data, features: [MKGeoJSONFeature]) {

        let key     = CacheKey(layerKey: layer, region: region)
        let bboxStr = region.toBboxString()

        // 1. Cek cache
        if let cached = cache.get(for: key) {
            let features = try decode(cached)
            return (cached, features)
        }

        // 2. Fetch dari network
        let data = try await api.fetchLayer(key: layer, bbox: bboxStr)

        // 3. Simpan ke cache
        cache.set(data, for: key)

        // 4. Decode
        let features = try decode(data)
        return (data, features)
    }

    // MARK: - Private

    private func decode(_ data: Data) throws -> [MKGeoJSONFeature] {
        let decoder = MKGeoJSONDecoder()
        let objects = try decoder.decode(data)
        return objects.compactMap { $0 as? MKGeoJSONFeature }
    }
}
