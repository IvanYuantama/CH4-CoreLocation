//
//  ContentView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 30/06/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Kanvas utama aplikasi kita sekarang sudah terenkapsulasi rapi di sini
        MapContainerView()
            // Di masa depan, jika kamu punya elemen global seperti
            // Custom Toast, Global Alert, atau App-wide State (EnvironmentObject),
            // kamu bisa menaruh modifier-nya di level ini.
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
