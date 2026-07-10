//
//  LanguagePreferenceView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct LanguagePreferenceView: View {
    @ObservedObject var vm: SettingsViewModel

    private var lang: String { vm.selectedLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(L.t(.languagePreference, lang))
                    .font(Theme.Typography.heading)
                    .foregroundColor(Color(.textPrimary))
                Spacer()
                Image(systemName: "translate").font(.title2)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            PreferenceRadioRow(
                title: "Indonesia",
                subtitle: "Bahasa Indonesia",
                isSelected: vm.selectedLanguage == "id"
            ) { selectLanguage("id") }

            Divider().padding(.leading, 24)

            PreferenceRadioRow(
                title: "English",
                subtitle: "United States",
                isSelected: vm.selectedLanguage == "en"
            ) { selectLanguage("en") }

            Spacer()
        }
        .background(Color(.background).ignoresSafeArea())
    }

    private func selectLanguage(_ code: String) {
        vm.selectedLanguage = code
        vm.directIndonesianFailed = false
    }
}

// MARK: - Komponen Helper: Radio Row
struct PreferenceRadioRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.Typography.option)
                        .foregroundColor(Color(.textPrimary))
                    Text(subtitle)
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(Color(.textSecondary))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(.brand) : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle().fill(Color(.iconBlue)).frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LanguagePreferenceView(vm: SettingsViewModel())
}
