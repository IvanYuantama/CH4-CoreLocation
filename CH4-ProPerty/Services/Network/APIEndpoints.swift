//
//  APIEndPoints.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import Foundation

enum APIEndpoints {
    static let baseURL = "https://property-backend-khaki.vercel.app"

    /// GET /api/analyze?lat=&lng=
    static func analyze(lat: Double, lng: Double) -> URLComponents {
        var c = URLComponents(string: "\(baseURL)/api/analyze")!
        c.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng))
        ]
        return c
    }

    /// GET /api/layers/:layerKey?bbox=west,south,east,north
    static func layer(key: LayerKey, bbox: String) -> URLComponents {
        var c = URLComponents(string: "\(baseURL)/api/layers/\(key.rawValue)")!
        c.queryItems = [
            URLQueryItem(name: "bbox", value: bbox)
        ]
        return c
    }
}
