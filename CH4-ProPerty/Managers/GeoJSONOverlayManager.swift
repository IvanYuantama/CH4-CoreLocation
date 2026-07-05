//
//  GeoJSONOverlayManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import MapKit
import UIKit

/// Mengelola lifecycle semua overlay polygon GeoJSON di MKMapView.
/// Track overlay per LayerKey → bisa hapus layer tertentu tanpa hapus semua.
/// Satu-satunya class yang boleh panggil addOverlay / removeOverlays.
@Observable
final class GeoJSONOverlayManager {

    // MARK: - State
    // overlay per layer agar bisa remove selektif
    private var overlaysByLayer: [LayerKey: [MKOverlay]] = [:]
    // warna per overlay — pakai ObjectIdentifier agar stabil (bukan AnyHashable)
    private var overlayColorMap: [ObjectIdentifier: UIColor] = [:]

    // Reference ke MKMapView — di-set dari MapContainerView saat makeUIView
    weak var mapView: MKMapView?

    // MARK: - Public: load layer dari backend + render

    /// Fetch → decode → cache → render overlay untuk satu layer.
    func loadAndRender(layer key: LayerKey, region: MKCoordinateRegion) async {
        do {
            let (_, features) = try await GeoJSONLoaderService.shared.load(
                layer: key,
                region: region
            )
            await MainActor.run {
                guard let mapView else { return }
                replace(layer: key, features: features, on: mapView)
            }
        } catch {
            print("[GeoJSONOverlayManager] Gagal load \(key.rawValue): \(error.localizedDescription)")
        }
    }

    // MARK: - Public: remove satu layer

    @MainActor
    func removeLayer(_ key: LayerKey) {
        guard let mapView,
              let overlays = overlaysByLayer[key] else { return }
        mapView.removeOverlays(overlays)
        overlays.forEach {
            overlayColorMap.removeValue(forKey: ObjectIdentifier($0 as AnyObject))
        }
        overlaysByLayer.removeValue(forKey: key)
    }

    // MARK: - Public: remove semua layer

    @MainActor
    func removeAllLayers() {
        guard let mapView else { return }
        let all = overlaysByLayer.values.flatMap { $0 }
        mapView.removeOverlays(all)
        overlaysByLayer.removeAll()
        overlayColorMap.removeAll()
    }

    // MARK: - Public: renderer (dipanggil dari MapCoordinator / MKMapViewDelegate)

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer {
        let id    = ObjectIdentifier(overlay as AnyObject)
        let color = overlayColorMap[id] ?? UIColor.systemGray

        if let polygon = overlay as? MKPolygon {
            let r = MKPolygonRenderer(polygon: polygon)
            r.fillColor   = color.withAlphaComponent(0.35)
            r.strokeColor = color.withAlphaComponent(0.8)
            r.lineWidth   = 1.0
            return r
        }
        if let multi = overlay as? MKMultiPolygon {
            let r = MKMultiPolygonRenderer(multiPolygon: multi)
            r.fillColor   = color.withAlphaComponent(0.35)
            r.strokeColor = color.withAlphaComponent(0.8)
            r.lineWidth   = 1.0
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: - Private

    @MainActor
    private func replace(
        layer key: LayerKey,
        features: [MKGeoJSONFeature],
        on mapView: MKMapView
    ) {
        // Hapus overlay lama untuk layer ini saja
        if let old = overlaysByLayer[key] {
            mapView.removeOverlays(old)
            old.forEach { overlayColorMap.removeValue(forKey: ObjectIdentifier($0 as AnyObject)) }
        }

        var newOverlays: [MKOverlay] = []

        for feature in features {
            // Decode warna dari properties JSON
            let color: UIColor
            if let propsData = feature.properties,
               let props = try? JSONDecoder().decode(FeatureProperties.self, from: propsData),
               let c = UIColor(hex: props.color) {
                color = c
            } else {
                color = .systemGray
            }

            for geometry in feature.geometry {
                guard let overlay = geometry as? MKOverlay else { continue }
                overlayColorMap[ObjectIdentifier(overlay as AnyObject)] = color
                newOverlays.append(overlay)
            }
        }

        overlaysByLayer[key] = newOverlays
        // aboveRoads → label jalan tetap terlihat di atas polygon
        mapView.addOverlays(newOverlays, level: .aboveRoads)
    }
}
