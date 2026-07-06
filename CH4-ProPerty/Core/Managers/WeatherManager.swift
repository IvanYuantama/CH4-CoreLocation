//
//  WeatherManager.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import Foundation
import CoreLocation
import WeatherKit
import Combine

@MainActor
final class WeatherManager: ObservableObject {
    struct Snapshot {
        let temperature: String
        let humidity: String
        let uv: String
        let weatherSymbol: String  
    }

    @Published var snapshot: Snapshot?
    @Published var isLoading = false
    private var lastFetchLocation: CLLocation?

    func loadIfNeeded(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let lastFetchLocation,
           snapshot != nil,
           lastFetchLocation.distance(from: location) < 25_000 {
            return
        }
        
        lastFetchLocation = location
        isLoading = true
        
        Task {
            defer { isLoading = false }
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                let current = weather.currentWeather
                let tempC = Int(current.temperature.converted(to: .celsius).value.rounded())
                let humidity = Int((current.humidity * 100).rounded())
                
                snapshot = Snapshot(
                    temperature: "\(tempC)°C",
                    humidity: "\(humidity)%",
                    uv: "\(current.uvIndex.value) UV",
                    weatherSymbol: current.symbolName
                )
            } catch {
                snapshot = Snapshot(
                    temperature: "--°C",
                    humidity: "--%",
                    uv: "-- UV",
                    weatherSymbol: "cloud.fill"
                )
            }
        }
    }
}
