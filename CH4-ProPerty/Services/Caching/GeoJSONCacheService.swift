//
//  GeoJSONCacheService.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

//  Two-tier cache: memory (NSCache) + disk (FileManager)
//  GeoJSON polygon bisa sangat besar (~1-5MB per layer per bbox),
//  cache menghindari re-fetch ke backend saat user scroll ke region yang sama.
//

import Foundation

final class GeoJSONCacheService {

    static let shared = GeoJSONCacheService()

    // MARK: - Memory Cache (hilang saat app di-kill)
    private let memCache = NSCache<NSString, NSData>()

    // MARK: - Disk Cache (persisten antar sesi)
    private let cacheDir: URL

    private init() {
        // Batas memory: 50MB untuk GeoJSON
        memCache.totalCostLimit = 50 * 1024 * 1024

        // Folder cache di Library/Caches (iOS bisa hapus saat storage penuh)
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = cachesDir.appending(path: "GeoJSONCache", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Get

    func get(for key: CacheKey) -> Data? {
        let nsKey = key.value as NSString

        // 1. Cek memory dulu (cepat)
        if let cached = memCache.object(forKey: nsKey) {
            return cached as Data
        }

        // 2. Cek disk
        let fileURL = cacheDir.appending(path: key.value)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        // Warm up memory cache
        memCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
        return data
    }

    // MARK: - Set

    func set(_ data: Data, for key: CacheKey) {
        let nsKey = key.value as NSString

        // Simpan ke memory
        memCache.setObject(data as NSData, forKey: nsKey, cost: data.count)

        // Simpan ke disk (background)
        let fileURL = cacheDir.appending(path: key.value)
        Task.detached(priority: .background) {
            try? data.write(to: fileURL)
        }
    }

    // MARK: - Clear

    func clearMemory() {
        memCache.removeAllObjects()
    }

    func clearDisk() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}
