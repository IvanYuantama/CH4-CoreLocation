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

    func fetch(for coordinate: CLLocationCoordinate2D, updating viewModel: MapViewModel) async {
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
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
            
            // Mengambil SF Symbol dinamis dari Apple (berdasarkan dokumentasi yang kamu baca!)
            let iconName = current.symbolName

            let attr = try await service.attribution
            
            await MainActor.run {
                viewModel.attributionLightURL = attr.combinedMarkLightURL
                viewModel.attributionDarkURL  = attr.combinedMarkDarkURL
                viewModel.attributionPageURL  = attr.legalPageURL
                
                // Tambahkan parameter iconName (pastikan kamu mengupdate fungsi updateWeather di MapViewModel)
                viewModel.updateWeather(
                    temp: tempC,
                    precipMM: precipMM,
                    humidityPct: humidity,
                    iconName: iconName
                )
            }

        } catch {
            print("[WeatherManager] Error: \(error.localizedDescription)")
            await MainActor.run {
                viewModel.updateWeather(temp: 0, precipMM: 0, humidityPct: 0, iconName: "exclamationmark.triangle.fill")
                viewModel.temperature   = "Err"
                viewModel.precipitation = "-- mm"
                viewModel.humidity      = "-- %"
            }
        }
    }
}
