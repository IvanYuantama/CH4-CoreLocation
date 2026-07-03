//
//  WeatherAttributionView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 03/07/26.
//

//  WAJIB ditampilkan setiap kali data WeatherKit ditampilkan di UI.
//  Requirement resmi Apple: https://developer.apple.com/weatherkit/data-source-attribution/
//  Tanpa ini app bisa ditolak App Store review.
//

import SwiftUI

struct WeatherAttributionView: View {
    let lightURL: URL?
    let darkURL:  URL?
    let pageURL:  URL?

    var body: some View {
        // Tampilkan hanya jika attribution sudah di-fetch
        if let lightURL, let darkURL {
            Link(destination: pageURL ?? URL(string: "https://weather-data.apple.com/legal-attribution.html")!) {
                // Pilih logo sesuai color scheme device
                AsyncImage(url: colorSchemeURL(light: lightURL, dark: darkURL)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                } placeholder: {
                    // Kosong saat loading — jangan tampilkan placeholder
                    EmptyView()
                }
            }
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    private func colorSchemeURL(light: URL, dark: URL) -> URL {
        colorScheme == .dark ? dark : light
    }
}
