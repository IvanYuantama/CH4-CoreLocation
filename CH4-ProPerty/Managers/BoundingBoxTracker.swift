//
//  BoundingBoxTracker.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

//  Debounce regionDidChangeAnimated agar tidak spam API saat user scroll/zoom.
//  Hanya fire callback setelah 500ms idle DAN bbox benar-benar berubah.
//

import MapKit

final class BoundingBoxTracker {

    private var currentTask: Task<Void, Never>?
    private var lastFiredKey: String?

    /// Dipanggil setiap kali region peta berubah.
    /// - Parameters:
    ///   - region: Region MKMapView saat ini
    ///   - onFire: Closure dipanggil setelah debounce dengan region final
    func onRegionChanged(
        _ region: MKCoordinateRegion,
        onFire: @escaping (MKCoordinateRegion) async -> Void
    ) {
        currentTask?.cancel()
        currentTask = Task {
            // Debounce 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            // Skip jika bbox sama (user scroll kecil < ~1km)
            let key = region.toBboxCacheKey()
            guard key != lastFiredKey else { return }
            lastFiredKey = key

            await onFire(region)
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}
