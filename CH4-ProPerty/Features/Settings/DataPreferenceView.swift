//
//  DataPreferenceView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct DataPreferenceView: View {
    @ObservedObject var vm: SettingsViewModel
    private var lang: String { vm.selectedLanguage }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L.t(.dataPreferences, lang))
                        .font(Theme.Typography.heading)
                        .foregroundColor(Color(.textPrimary))
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title2)
                        .foregroundColor(Color(.textPrimary))
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                Group {
                    row(.temperature, .temperatureSub, vm.showTemperature) { vm.showTemperature.toggle() }
                    divider
                    row(.floodRisk, .floodRiskSub, vm.showFloodRisk) { vm.showFloodRisk.toggle() }
                    divider
                    row(.airQuality, .airQualitySub, vm.showAirQuality) { vm.showAirQuality.toggle() }
                    divider
                    row(.greenSpaces, .greenSpacesSub, vm.showGreenSpaces) { vm.showGreenSpaces.toggle() }
                    divider
                    row(.roadAccess, .roadAccessSub, vm.showRoadAccess) { vm.showRoadAccess.toggle() }
                    divider
                    row(.publicFacilities, .publicFacilitiesSub, vm.showPublicFacilities) { vm.showPublicFacilities.toggle() }
                    divider
                    row(.population, .populationSub, vm.showPopulation) { vm.showPopulation.toggle() }
                    divider
                    row(.families, .familiesSub, vm.showFamilies) { vm.showFamilies.toggle() }
                    divider
                    row(.elevation, .elevationSub, vm.showElevation) { vm.showElevation.toggle() }
                    divider
                    row(.crimeData, .crimeDataSub, vm.showCrimeData) { vm.showCrimeData.toggle() }
                    divider
                    row(.networkConnectivity, .networkConnectivitySub, vm.showNetworkData) { vm.showNetworkData.toggle() }
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(.background).ignoresSafeArea())
    }

    private var divider: some View { Divider().padding(.leading, 24) }

    private func row(_ title: LocKey, _ sub: LocKey, _ isOn: Bool, _ action: @escaping () -> Void) -> some View {
        PreferenceRadioRow(title: L.t(title, lang), subtitle: L.t(sub, lang), isSelected: isOn, action: action)
    }
}

#Preview {
    DataPreferenceView(vm: SettingsViewModel())
}
