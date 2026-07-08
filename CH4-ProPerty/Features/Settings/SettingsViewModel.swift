//
//  SettingsViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage("appLanguage") var selectedLanguage: String = "en"
    @AppStorage("appColorScheme") var appColorScheme: String = "system"
    
    @AppStorage("showTemperature") var showTemperature: Bool = true
    @AppStorage("showFloodRisk") var showFloodRisk: Bool = true
    @AppStorage("showAirQuality") var showAirQuality: Bool = true
    @AppStorage("showGreenSpaces") var showGreenSpaces: Bool = true
    @AppStorage("showRoadAccess") var showRoadAccess: Bool = true
    @AppStorage("showPublicFacilities") var showPublicFacilities: Bool = true
    @AppStorage("showPopulation") var showPopulation: Bool = true
    @AppStorage("showFamilies") var showFamilies: Bool = true
    @AppStorage("showElevation") var showElevation: Bool = true
    @AppStorage("showCrimeData") var showCrimeData: Bool = true
    @AppStorage("showNetworkData") var showNetworkData: Bool = true
    
    var activeColorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
