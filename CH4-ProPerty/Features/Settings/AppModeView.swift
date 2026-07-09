//
//  AppModeView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct AppModeView: View {
    @ObservedObject var vm: SettingsViewModel
    private var lang: String { vm.selectedLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(L.t(.appMode, lang))
                    .font(Theme.Typography.heading)
                    .foregroundColor(Color(.textPrimary))
                Spacer()
                Image(systemName: "circle.righthalf.filled").font(.title2)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            PreferenceRadioRow(
                title: L.t(.dark, lang), subtitle: L.t(.darkSub, lang),
                isSelected: vm.appColorScheme == "dark"
            ) { vm.appColorScheme = "dark" }

            Divider().padding(.leading, 24)

            PreferenceRadioRow(
                title: L.t(.light, lang), subtitle: L.t(.lightSub, lang),
                isSelected: vm.appColorScheme == "light"
            ) { vm.appColorScheme = "light" }

            Divider().padding(.leading, 24)

            PreferenceRadioRow(
                title: L.t(.system, lang), subtitle: L.t(.systemSub, lang),
                isSelected: vm.appColorScheme == "system"
            ) { vm.appColorScheme = "system" }

            Spacer()
        }
        .background(Color(.background).ignoresSafeArea())
    }
}

#Preview {
    AppModeView(vm: SettingsViewModel())
}
