//
//  SmallCard.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 07/07/26.
//

import SwiftUI

struct SmallCard: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Garis Biru Vertikal di Kiri
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.brand))
                .frame(width: 5, height: 37)

            // Teks Title & Value
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
        }
        .frame(width: 165, height: 67)
    }
}

#Preview {
    VStack(spacing: 0) {
        SmallCard(title: "Wifi (Download)", value: "68.9 Mbps")
        SmallCard(title: "Cellular (Upload)", value: "14.2 Mbps")
    }
    .padding(.horizontal, 20)
//    .background(Color.white)
}
