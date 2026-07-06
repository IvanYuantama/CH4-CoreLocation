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

    enum SettingSheet: Identifiable {
        case language, mode, data
        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 24) {
            Button { activeSheet = .language } label: {
                Image(systemName: "translate")
            }
            Button { activeSheet = .mode } label: {
                Image(systemName: "circle.righthalf.filled")
            }
            Button { activeSheet = .data } label: {
                Image(systemName: "bubble.left.and.bubble.right")
            }
        }
        .font(.system(size: 20))
        .foregroundColor(Theme.textPrimary)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .language:
                    LanguagePreferenceView(vm: vm)
                case .mode:
                    AppModeView(vm: vm)
                case .data:
                    DataPreferenceView(vm: vm)
                }
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(Theme.sheetRadius)
        }
    }
}

#Preview("Settings Menu") {
    SettingsMenuView()
        .environmentObject(SettingsViewModel())
}
