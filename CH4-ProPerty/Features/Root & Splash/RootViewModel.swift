//
//  RootViewModel.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import Combine

@MainActor
class RootViewModel: ObservableObject {
    @Published var isShowingSplash = true

    func startSplashTimer() async {
        try? await Task.sleep(for: .seconds(1.8))
        withAnimation(.easeOut(duration: 0.5)) {
            self.isShowingSplash = false
        }
    }
}
