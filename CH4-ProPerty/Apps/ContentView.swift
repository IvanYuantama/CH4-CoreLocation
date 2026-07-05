//
//  ContentView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

/// Root view: Splash (1.8s) → fade → MapContainerView.
struct ContentView: View {

    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            // Peta utama selalu ada di bawah, hanya opacity-nya yang berubah
            MapContainerView()
                .opacity(isShowingSplash ? 0 : 1)

            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.5)) {
                isShowingSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}
