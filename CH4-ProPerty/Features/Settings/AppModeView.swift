//
//  AppModeView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct AppModeView: View {
    @ObservedObject var vm: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("App Mode")
                    .font(Theme.Typography.heading)
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: "circle.righthalf.filled")
                    .font(.title2)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            
            PreferenceRadioRow(
                title: "Dark",
                subtitle: "Make your app mode set to dark",
                isSelected: vm.appColorScheme == "dark"
            ) { vm.appColorScheme = "dark" }
            
            Divider().padding(.leading, 24)
            
            PreferenceRadioRow(
                title: "Light",
                subtitle: "Make your app mode set to light",
                isSelected: vm.appColorScheme == "light"
            ) { vm.appColorScheme = "light" }
            
            Divider().padding(.leading, 24)
            
            PreferenceRadioRow(
                title: "System",
                subtitle: "Make your app mode set to automatic",
                isSelected: vm.appColorScheme == "system"
            ) { vm.appColorScheme = "system" }
            
            Spacer()
        }
        .background(Color.background.ignoresSafeArea())
    }
}

#Preview {
    AppModeView(vm: SettingsViewModel())
}
