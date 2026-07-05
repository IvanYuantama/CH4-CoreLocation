//
//  RootView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var vm = RootViewModel()

    var body: some View {
        ZStack {
            MainMapView()
                .opacity(vm.isShowingSplash ? 0 : 1)
            
            if vm.isShowingSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            await vm.startSplashTimer()
        }
    }
}

#Preview {
    RootView()
}
