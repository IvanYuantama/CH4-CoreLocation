//
//  WeatherManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import WeatherKit
import CoreLocation
import SwiftUI

@Observable
final class WeatherManager {

    private let service = WeatherService.shared

    // MARK: - Attribution (wajib ditampilkan per Apple policy)
    var attributionLightURL: URL?
    var attributionDarkURL:  URL?
    var attributionPageURL:  URL?

    // MARK: - Skip guard (hemat quota 500k/bulan)
    // Dari teman tim: skip fetch jika pindah < 25km dari lokasi fetch terakhir
    private var lastFetchLocation: CLLocation?

    // MARK: - Fetch

    func fetch(for coordinate: CLLocationCoordinate2D, updating viewModel: MapViewModel) async {

        // Preview guard
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            await MainActor.run {
                viewModel.updateWeather(temp: 26.0, precipMM: 1.2, humidityPct: 59, uvIndex: 1)
            }
            return
        }

        // Skip jika < 25km dari fetch terakhir (dari teman tim)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let last = lastFetchLocation,
           viewModel.isWeatherLoading == false,
           last.distance(from: location) < 25_000 {
            return
        }
        lastFetchLocation = location

        do {
            // Fetch current + hourly dalam satu request
            let (current, hourly) = try await service.weather(
                for: location,
                including: .current, .hourly
            )

            let tempC    = current.temperature.converted(to: .celsius).value
            let humidity = Int(current.humidity * 100)
            let precipMM = hourly.forecast.first?
                .precipitationAmount
                .converted(to: .millimeters)
                .value ?? 0
            // UV index — dari teman tim
            let uvIndex  = current.uvIndex.value

            // Attribution wajib
            let attr = try await service.attribution
            await MainActor.run {
                self.attributionLightURL = attr.combinedMarkLightURL
                self.attributionDarkURL  = attr.combinedMarkDarkURL
                self.attributionPageURL  = attr.legalPageURL
                viewModel.updateWeather(
                    temp: tempC,
                    precipMM: precipMM,
                    humidityPct: humidity,
                    uvIndex: uvIndex
                )
            }

        } catch {
            print("[WeatherManager] Error: \(error.localizedDescription)")
            await MainActor.run {
                viewModel.updateWeather(temp: 0, precipMM: 0, humidityPct: 0, uvIndex: 0)
                viewModel.temperature   = "Err"
                viewModel.precipitation = "-- mm"
                viewModel.humidity      = "-- %"
                viewModel.uvIndex       = "-- UV"
            }
        }
    }
}
