//
//  CustomPinMarker.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI

struct CustomPinMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                // Menggunakan warna pin merah yang sudah ada di Theme sebelumnya
                .fill(.markerHead)
                .frame(width: 19, height: 19)
            
            Rectangle()
                .fill(.markerNeedle)
                .frame(width: 3, height: 20)
        }
    }
}

struct CustomPinMarkerMini: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                // Menggunakan warna pin merah yang sudah ada di Theme sebelumnya
                .fill(.markerHead)
                .frame(width: 10, height: 10)
            
            Rectangle()
                .fill(.markerNeedle)
                .frame(width: 1.58, height: 9.6)
        }
    }
}

#Preview {
    CustomPinMarker()
    CustomPinMarkerMini()
}
