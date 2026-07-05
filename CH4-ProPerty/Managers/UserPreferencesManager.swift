//
//  UserPreferencesManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

/// Menyimpan preferensi user secara persisten via @AppStorage.
/// Data tetap ada antar sesi app.
@Observable
final class UserPreferencesManager {

    // MARK: - Active Layers
    // Simpan sebagai JSON string karena @AppStorage tidak support Set<String>
    @ObservationIgnored
    @AppStorage("activeLayerIDs") private var activeLayerIDsRaw: String = ""

    var activeLayerIDs: Set<LayerKey> {
        get {
            let ids = activeLayerIDsRaw
                .split(separator: ",")
                .map(String.init)
            return Set(ids.compactMap { LayerKey(rawValue: $0) })
        }
        set {
            activeLayerIDsRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    // MARK: - Map Style Preference
    @ObservationIgnored
    @AppStorage("lastMapStyle") private var lastMapStyleRaw: String = "standard"

    var lastMapStyle: MapStyleOption {
        get { lastMapStyleRaw == "satellite" ? .satellite : .standard }
        set { lastMapStyleRaw = newValue == .satellite ? "satellite" : "standard" }
    }

    // MARK: - Has seen onboarding
    @ObservationIgnored
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    // MARK: - Helpers

    func toggle(layer key: LayerKey) {
        if activeLayerIDs.contains(key) {
            activeLayerIDs.remove(key)
        } else {
            activeLayerIDs.insert(key)
        }
    }

    func isActive(_ key: LayerKey) -> Bool {
        activeLayerIDs.contains(key)
    }

    func resetLayers() {
        activeLayerIDs = []
    }
}
