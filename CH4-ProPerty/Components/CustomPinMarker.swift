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
                .fill(Color(red: 0.89, green: 0.22, blue: 0.21))
                .frame(width: 19, height: 19)
            
            Rectangle()
                .fill(Color.black)
                .frame(width: 3, height: 20)
        }
    }
}

struct CustomPinMarkerMini: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(red: 0.89, green: 0.22, blue: 0.21))
                .frame(width: 10, height: 10)
            
            Rectangle()
                .fill(Color.black)
                .frame(width: 1.58, height: 9.6)
        }
    }
}

#Preview {
    CustomPinMarker()
    CustomPinMarkerMini()
}
