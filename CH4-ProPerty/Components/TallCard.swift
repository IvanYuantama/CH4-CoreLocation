//
//  TallCard.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct TallCard: View {
    let title: String
    let value: String
    let decorativeIcon: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Typography.subsection)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(value)
                    .font(Theme.Typography.heading)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: decorativeIcon)
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.primary)
                        .padding(.trailing, 16)
                        .padding(.bottom, 4)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .padding(.leading, 8)

            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.primary)
                .frame(width: 5, height: 106)
                .padding(.top, 5)
        }
        .frame(width: 163, height: 116)
    }
}

#Preview {
    HStack(alignment: .top, spacing: 0) {

        TallCard(title: "Flood Risk", value: "High", decorativeIcon: "water.waves")
            .frame(width: 163, height: 116)
    }
    .padding(.horizontal, 20)
    .background(Color.white)
}
