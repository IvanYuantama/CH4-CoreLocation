//
//  LocationAnalysisAPIService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import Foundation
import CoreLocation
import MapKit

final class LocationAnalysisAPIService: LocationAnalysisAPIServiceProtocol {

    static let shared = LocationAnalysisAPIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Point Analysis

    func analyzePoint(coordinate: CLLocationCoordinate2D) async throws -> PointAnalysisResponse {
        let components = APIEndpoints.analyze(
            lat: coordinate.latitude,
            lng: coordinate.longitude
        )
        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(statusCode: 0)
        }
        guard http.statusCode == 200 else {
            throw APIError.invalidResponse(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(PointAnalysisResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - GeoJSON Layer

    func fetchLayer(key: LayerKey, bbox: String) async throws -> Data {
        let components = APIEndpoints.layer(key: key, bbox: bbox)
        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(statusCode: 0)
        }
        guard http.statusCode == 200 else {
            throw APIError.invalidResponse(statusCode: http.statusCode)
        }

        return data
    }
}
