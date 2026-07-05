//
//  LayerFilterViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI
import MapKit

/// Mengelola state toggle 8 layer analisis dan trigger load/remove overlay di peta.
@Observable
final class LayerFilterViewModel {

    // MARK: - Dependencies
    private let overlayManager: GeoJSONOverlayManager
    private let preferences:    UserPreferencesManager

    // MARK: - State
    var activeLayerIDs: Set<LayerKey> = []
    var currentRegion: MKCoordinateRegion?
    var loadingLayers: Set<LayerKey> = []

    // MARK: - Init
    init(
        overlayManager: GeoJSONOverlayManager,
        preferences: UserPreferencesManager
    ) {
        self.overlayManager = overlayManager
        self.preferences    = preferences
        self.activeLayerIDs = preferences.activeLayerIDs
    }

    // MARK: - Public

    func toggle(_ key: LayerKey) {
        if activeLayerIDs.contains(key) {
            deactivate(key)
        } else {
            activate(key)
        }
    }

    func isActive(_ key: LayerKey) -> Bool {
        activeLayerIDs.contains(key)
    }

    func isLoading(_ key: LayerKey) -> Bool {
        loadingLayers.contains(key)
    }

    func reloadActiveLayers(for region: MKCoordinateRegion) {
        currentRegion = region
        for key in activeLayerIDs {
            loadLayer(key, region: region)
        }
    }

    // MARK: - Private

    private func activate(_ key: LayerKey) {
        activeLayerIDs.insert(key)
        preferences.activeLayerIDs = activeLayerIDs
        guard let region = currentRegion else { return }
        loadLayer(key, region: region)
    }

    private func deactivate(_ key: LayerKey) {
        activeLayerIDs.remove(key)
        preferences.activeLayerIDs = activeLayerIDs
        overlayManager.removeLayer(key)
    }

    private func loadLayer(_ key: LayerKey, region: MKCoordinateRegion) {
        loadingLayers.insert(key)
        // FIX: Task @MainActor — eksekusi di main thread tanpa MainActor.run
        // Menghindari warning "Result of call to 'run(resultType:body:)' is unused"
        Task { @MainActor in
            await overlayManager.loadAndRender(layer: key, region: region)
            loadingLayers.remove(key)
        }
    }
}
