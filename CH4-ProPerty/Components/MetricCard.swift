//
//  MetricCard.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var isTall: Bool = false
    var decorativeIcon: String? = nil

    var body: some View {
        if isTall {
            TallCard(
                title: title,
                value: value,
                decorativeIcon: decorativeIcon ?? icon
            )
        } else if icon.isEmpty {
            SmallCard(
                title: title,
                value: value
            )
        } else {
            NormalCard(
                title: title,
                value: value,
                icon: icon
            )
        }
    }
}

#Preview {
    ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: Environment
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment")
                    .font(Theme.Typography.section)

                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        MetricCard(title: "Temperature", value: "Low", icon: "thermometer.medium")
                        MetricCard(title: "Air Quality", value: "Medium", icon: "wind")
                    }
                    .frame(maxWidth: .infinity)

                    MetricCard(title: "Flood Risk", value: "High", icon: "water.waves", isTall: true, decorativeIcon: "water.waves")
                        .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // MARK: Accessibilities
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessibilities")
                    .font(Theme.Typography.section)

                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        MetricCard(title: "Green Spaces", value: "Dense", icon: "tree")
                        MetricCard(title: "Pub. Facilities", value: "School", icon: "building.2")
                    }
                    .frame(maxWidth: .infinity)

                    MetricCard(title: "Road Access", value: "Collector", icon: "road.lanes", isTall: true, decorativeIcon: "road.lanes")
                        .frame(maxWidth: .infinity)
                }

                HStack(spacing: 0) {
                    MetricCard(title: "Pub. Facilities", value: "Hospital", icon: "cross.case")
                        .frame(maxWidth: .infinity)

                    MetricCard(title: "Pub. Facilities", value: "Police", icon: "building.columns")
                        .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // MARK: Social
            VStack(alignment: .leading, spacing: 8) {
                Text("Social")
                    .font(Theme.Typography.section)

                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        MetricCard(title: "Population", value: "55.352", icon: "person.2")
                        MetricCard(title: "Families", value: "16.798", icon: "figure.2.and.child.holdinghands")
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Tambahan Crime Case sebagai Tall Card sesuai desain HiFi
                    MetricCard(title: "Crime Case", value: "1027 / yr", icon: "exclamationmark.shield", isTall: true, decorativeIcon: "exclamationmark.shield")
                        .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // MARK: Geography
            VStack(alignment: .leading, spacing: 8) {
                Text("Geography")
                    .font(Theme.Typography.section)

                HStack(spacing: 0) {
                    MetricCard(title: "Elevation", value: "Lowland", icon: "mountain.2")
                        .frame(maxWidth: .infinity)

                    Spacer().frame(maxWidth: .infinity)
                }
            }
            
            Divider()
            
            // MARK: Network
            VStack(alignment: .leading, spacing: 8) {
                Text("Network")
                    .font(Theme.Typography.section)

                HStack(spacing: 0) {
                    MetricCard(title: "Wifi (Download)", value: "68.9 Mbps", icon: "")
                        .frame(maxWidth: .infinity)

                    MetricCard(title: "Wifi (Upload)", value: "52.7 Mbps", icon: "")
                        .frame(maxWidth: .infinity)
                }
                
                HStack(spacing: 0) {
                    MetricCard(title: "Cellular (Download)", value: "30.9 Mbps", icon: "")
                        .frame(maxWidth: .infinity)

                    MetricCard(title: "Cellular (Upload)", value: "14.2 Mbps", icon: "")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
//    .background(Color.white)
}
