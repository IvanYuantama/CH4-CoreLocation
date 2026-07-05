//
//  SplashView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 04/07/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            LogoMark()
                .frame(width: 130, height: 150)

            // FIX: Ganti + Text concatenation (deprecated iOS 26)
            // dengan Text("\(Text())") string interpolation
            Text("\(Text("Pro").foregroundColor(Theme.primary))Perty")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(.black)

            Text("Consider your property like a professional")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
    }
}

struct LogoMark: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(.black)
                .frame(width: 18, height: 150)
                .offset(x: -30)

            RoundedRectangle(cornerRadius: 30)
                .fill(Theme.primary)
                .frame(width: 66, height: 84)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Theme.accent, lineWidth: 9)
                )
                .offset(x: 14, y: -30)
        }
    }
}
