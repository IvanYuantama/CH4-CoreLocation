//
//  SettingsMenuView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct SettingsMenuView: View {
    @EnvironmentObject private var vm: SettingsViewModel
    @State private var activeSheet: SettingSheet?

    private var lang: String { vm.selectedLanguage }

    enum SettingSheet: Identifiable {
        case language, mode, data
        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 24) {
            Button { activeSheet = .language } label: {
                Image(systemName: "translate")
            }
            .frame(width: 30)
            .contentShape(Rectangle())
            .accessibilityLabel(L.t(.menuLanguage, lang))

            Button { activeSheet = .mode } label: {
                Image(systemName: "circle.righthalf.filled")
            }
            .frame(width: 30)
            .contentShape(Rectangle())
            .accessibilityLabel(L.t(.menuMode, lang))

            Button { activeSheet = .data } label: {
                Image(systemName: "bubble.left.and.bubble.right")
            }
            .frame(width: 30)
            .contentShape(Rectangle())
            .accessibilityLabel(L.t(.menuData, lang))
        }
        .font(.system(size: 20))
        .foregroundColor(Color(.textPrimary))
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.background))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .language: LanguagePreferenceView(vm: vm)
                case .mode:     AppModeView(vm: vm)
                case .data:     DataPreferenceView(vm: vm)
                }
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(Theme.sheetRadius)
            .preferredColorScheme(vm.activeColorScheme)
        }
    }
}

#Preview("Settings Menu") {
    SettingsMenuView().environmentObject(SettingsViewModel())
}
