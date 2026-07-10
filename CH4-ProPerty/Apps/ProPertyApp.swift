//
//  ProPertyApp.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

@main
struct ProPertyApp: App {
    @StateObject private var settingsVM = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(settingsVM.activeColorScheme)
        }
    }
}
