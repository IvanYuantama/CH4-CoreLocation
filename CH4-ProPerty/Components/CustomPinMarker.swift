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
                .fill(Color(red: 0.89, green: 0.22, blue: 0.21))
                .frame(width: 16, height: 16)
            
            Rectangle()
                .fill(Color.black)
                .frame(width: 2, height: 16)
        }
    }
}

#Preview {
    CustomPinMarker()
}
