//
//  APIError.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(Error)
    case serverError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL tidak valid."
        case .invalidResponse(let code):
            return "Response server tidak valid (HTTP \(code))."
        case .decodingFailed(let error):
            return "Gagal decode data: \(error.localizedDescription)"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .noData:
            return "Tidak ada data yang diterima."
        }
    }
}
