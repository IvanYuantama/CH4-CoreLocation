//
//  IndexView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 01/07/26.
//

import SwiftUI

struct IndexView: View {
    @State private var selection = 1
    
    var body: some View {
        TabView(selection: $selection) {
            MapView()
                .tabItem {
                    Label("MapKit", systemImage: "map")
                }
                .tag(1)
            
            Map2View()
                .tabItem {
                    Label("GeoToolBox", systemImage: "shippingbox.fill")
                }
            
            AIView()
                .tabItem {
                    Label("AI", systemImage: "apple.intelligence")
                }
        }
    }
}

#Preview {
    IndexView()
}
