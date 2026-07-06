//
//  SplashView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 26) {
            // Kita hapus Spacer() di atas agar konten tidak terdorong ke bawah
            
            Image("app-logo") // Pastikan nama aset di Assets.xcassets benar
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Text("Consider your property like a professional")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            
            // Kita hapus juga Spacer() di bawah
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Memaksa VStack mengisi seluruh layar
        .background(Theme.background)
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
