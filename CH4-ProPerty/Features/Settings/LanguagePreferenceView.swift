//
//  LanguagePreferenceView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct LanguagePreferenceView: View {
    @ObservedObject var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Language Preference")
                    .font(Theme.Typography.heading)
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: "translate")
                    .font(.title2)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            
            // Opsi Indonesia
            PreferenceRadioRow(
                title: "Indonesia",
                subtitle: "Bahasa Indonesia",
                isSelected: vm.selectedLanguage == "id"
            ) {
                vm.selectedLanguage = "id"
            }
            
            Divider().padding(.leading, 24)
            
            // Opsi English
            PreferenceRadioRow(
                title: "English",
                subtitle: "United States",
                isSelected: vm.selectedLanguage == "en"
            ) {
                vm.selectedLanguage = "en"
            }
            
            Spacer()
        }
        .background(Color.background.ignoresSafeArea())
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
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                
                // Indikator Radio Button kustom
                ZStack {
                    Circle()
                        .stroke(isSelected ? .brand : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(.brand)
                            .frame(width: 12, height: 12)
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
