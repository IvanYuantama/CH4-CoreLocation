//
//  LocationAnalysisAPIServiceProtocol.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import CoreLocation
import MapKit

protocol LocationAnalysisAPIServiceProtocol {
    /// Analisis kondisi satu titik koordinat dari semua layer spasial
    /// GET /api/analyze?lat=&lng=
    func analyzePoint(coordinate: CLLocationCoordinate2D) async throws -> PointAnalysisResponse

    /// Ambil GeoJSON satu layer untuk bbox tertentu
    /// GET /api/layers/:layerKey?bbox=west,south,east,north
    func fetchLayer(key: LayerKey, bbox: String) async throws -> Data
}
