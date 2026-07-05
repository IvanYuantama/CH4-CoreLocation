//
//  ParameterItemView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 01/07/26.
//

import SwiftUI

struct ParameterItemView: View {
    var icon: String
    var text: String
    var color: String = "#000000"
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .shadow(radius: 4)
                .foregroundStyle(.blue)
                .font(.system(size: 24))
            
            Spacer()
            
            Text(text)
                .foregroundColor(Color(hex: color))
        }
        .padding(.top)
    }
}

#Preview {
    ParameterItemView(icon: "water.waves", text: "Tinggi")
}
