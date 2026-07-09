//
//  SplashView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct SplashView: View {
    @AppStorage("appLanguage") private var lang: String = "en"

    var body: some View {
        VStack(spacing: 26) {
            Image("app-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

            Text(L.t(.splashTagline, lang))
                .font(.footnote)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.background))
        .ignoresSafeArea()
    }
}
#Preview {
    SplashView()
}
