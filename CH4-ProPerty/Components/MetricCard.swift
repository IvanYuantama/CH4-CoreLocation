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
    var isReversed: Bool = false
    var isTall: Bool = false
    var decorativeIcon: String? = nil

    var body: some View {
        if isTall {
            tallCard
        } else {
            normalCard
        }
    }

    // MARK: - Normal Card
    private var normalCard: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.brand)
                .frame(width: 4, height: 40)
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(value)
                        .font(Theme.Typography.section)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.brand)
                    .frame(width: 28)
            }
            .padding(.vertical, 12)
            .padding(.leading, 12)
            .padding(.trailing, 4)
        }
    }

    // MARK: - Tall Card
    private var tallCard: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.subtitle)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                Text(value)
                    .font(Theme.Typography.section)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: decorativeIcon ?? icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.brand)
                        .frame(width: 28)
                }
            }
            .padding(.bottom, 12)
            .padding(.leading, 8)
            .padding(.trailing, 8)

            RoundedRectangle(cornerRadius: 2)
                .fill(.brand)
                .frame(width: 4)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: Environment
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment")
                    .font(Theme.Typography.section)
                    .padding(.horizontal, 20)

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        MetricCard(
                            title: "Temperature",
                            value: "Low",
                            icon: "thermometer.medium"
                        )
                        MetricCard(
                            title: "Air Quality",
                            value: "Medium",
                            icon: "wind"
                        )
                    }
                    .frame(maxWidth: .infinity)

                    MetricCard(
                        title: "Flood Risk",
                        value: "High",
                        icon: "water.waves",
                        isReversed: true,
                        isTall: true,
                        decorativeIcon: "water.waves"
                    )
                    .frame(width: 140)
                }
                .padding(.horizontal, 20)
            }

            Divider().padding(.horizontal, 20)

            // MARK: Accessibilities
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessibilities")
                    .font(Theme.Typography.section)
                    .padding(.horizontal, 20)

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        MetricCard(
                            title: "Green Spaces",
                            value: "Dense",
                            icon: "tree"
                        )
                        MetricCard(
                            title: "Pub. Facilities",
                            value: "School",
                            icon: "building.2"
                        )
                    }
                    .frame(maxWidth: .infinity)

                    MetricCard(
                        title: "Road Access",
                        value: "Collector",
                        icon: "road.lanes",
                        isReversed: true,
                        isTall: true,
                        decorativeIcon: "road.lanes"
                    )
                    .frame(width: 140)
                }
                .padding(.horizontal, 20)

                HStack(spacing: 16) {
                    MetricCard(
                        title: "Pub. Facilities",
                        value: "Hospital",
                        icon: "cross.case"
                    )
                    .frame(maxWidth: .infinity)

                    MetricCard(
                        title: "Pub. Facilities",
                        value: "Police",
                        icon: "building.columns",
                        isReversed: true
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
    }
    .background(Color.white)
}
