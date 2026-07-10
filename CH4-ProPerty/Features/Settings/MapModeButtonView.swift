//
//  MapModeButtonView.swift
//  CH4-ProPerty
//
//  Created by Ryan Tjendana on 08/07/26.
//

import SwiftUI

struct MapModeButtonView: View {
    @ObservedObject var vm: MainMapViewModel

    @State private var mapModePressed = false
    @State private var activeSheet = false

    var body: some View {
        Button {
            withAnimation(.bouncy(duration: 0.1)) {
                mapModePressed = true
            }

            activeSheet = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.bouncy) {
                    mapModePressed = false
                }
            }

        } label: {
            Image(systemName: vm.mapMode == .satellite
                  ? "globe.americas.fill"
                  : "map.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(.textPrimary))
                .frame(width: 50, height: 45)
                .background(Color(.background))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                .scaleEffect(mapModePressed ? 1.2 : 1)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $activeSheet) {
            MapModeView(mapMode: $vm.mapMode)
                .presentationDetents([.height(300)])
                .presentationCornerRadius(Theme.sheetRadius)
        }
    }
}

#Preview {
    MapModeButtonView(vm: MainMapViewModel())
}
