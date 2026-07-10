//
//  CompassView.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 09/07/26.
//

import SwiftUI
import CoreLocation

struct CompassView: View {
    let heading: CLLocationDirection     
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                CompassNeedle()                            
                    .rotationEffect(.degrees(-heading))
            }
            .frame(width: 45, height: 45)
        }
        .buttonStyle(.plain)
    }
}

private struct CompassNeedle: View {
    var body: some View {
        VStack(spacing: 0) {
            CompassTriangle().fill(.red).frame(width: 9, height: 13)
            CompassTriangle().fill(Color(.systemGray3))
                .rotationEffect(.degrees(180)).frame(width: 9, height: 13)
        }
    }
}

private struct CompassTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
