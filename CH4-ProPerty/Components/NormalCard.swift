//
//  NormalCard.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct NormalCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.brand))
                .frame(width: 5, height: 37)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Typography.text)
                    .foregroundColor(Color(.textPrimary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(Theme.Typography.subheading)
                    .foregroundColor(Color(.textPrimary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color(.brand))
        }
        .frame(width: 165, height: 67)
    }
}

#Preview {
    VStack(spacing: 0) {
        NormalCard(title: "Temperature", value: "Low", icon: "thermometer.medium")
        NormalCard(title: "Air Quality", value: "Medium", icon: "wind")
    }
    .padding(.horizontal, 20)
//    .background(Color.white)
}
