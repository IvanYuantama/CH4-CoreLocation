//
//  DataPreferenceView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct DataPreferenceView: View {
    @ObservedObject var vm: SettingsViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Data Preferences")
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
                    PreferenceRadioRow(title: "Temperature", subtitle: "Display the average temperature", isSelected: vm.showTemperature) { vm.showTemperature.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Flood Risk", subtitle: "Display the risk of flooding", isSelected: vm.showFloodRisk) { vm.showFloodRisk.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Air Quality", subtitle: "Display the air quality level", isSelected: vm.showAirQuality) { vm.showAirQuality.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Green Spaces", subtitle: "Display green space availability", isSelected: vm.showGreenSpaces) { vm.showGreenSpaces.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Road Access", subtitle: "Display primary road access type", isSelected: vm.showRoadAccess) { vm.showRoadAccess.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Public Facilities", subtitle: "Display nearby public facilities", isSelected: vm.showPublicFacilities) { vm.showPublicFacilities.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Population", subtitle: "Display area population count", isSelected: vm.showPopulation) { vm.showPopulation.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Families", subtitle: "Display total families in the area", isSelected: vm.showFamilies) { vm.showFamilies.toggle() }
                    
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Elevation", subtitle: "Display geography elevation level", isSelected: vm.showElevation) { vm.showElevation.toggle() }
                    
                    // 🌟 BARU: Toggle untuk Crime
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Crime Data", subtitle: "Display reported criminal cases", isSelected: vm.showCrimeData) { vm.showCrimeData.toggle() }
                    
                    // 🌟 BARU: Toggle untuk Network
                    Divider().padding(.leading, 24)
                    PreferenceRadioRow(title: "Network Connectivity", subtitle: "Display WiFi and Cellular speeds", isSelected: vm.showNetworkData) { vm.showNetworkData.toggle() }
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.background).ignoresSafeArea())
    }
}

#Preview {
    DataPreferenceView(vm: SettingsViewModel())
}
