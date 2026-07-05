//
//  MagnetInspectorView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import SwiftUI

/// Tampilan utama: tempelkan iPhone ke body mobil, kalibrasi di area logam asli,
/// lalu geser ke panel lain untuk membandingkan kekuatan medan magnetnya.
struct MagnetInspectorView: View {
    @StateObject private var manager = MagnetometerManager()

    var body: some View {
        VStack(spacing: 24) {
            Text("Deteksi Dempul / Lapisan Logam")
                .font(.headline)

            statusIndicator

            VStack(spacing: 6) {
                Text("Medan magnet: \(manager.currentMagnitude, specifier: "%.1f") µT")
                    .font(.system(.title2, design: .monospaced))

                if let baseline = manager.baselineMagnitude {
                    Text("Referensi (logam asli): \(baseline, specifier: "%.1f") µT")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                    Text("Selisih dari referensi: \(manager.deviationPercent, specifier: "%.1f")%")
                        .foregroundStyle(manager.deviationPercent < 0 ? .red : .green)
                        .font(.subheadline.weight(.medium))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ambang sensitivitas dempul: \(Int(manager.fillerThresholdPercent))%")
                    .font(.footnote)
                Slider(
                    value: Binding(
                        get: { manager.fillerThresholdPercent },
                        set: { manager.fillerThresholdPercent = $0 }
                    ),
                    in: 10...50, step: 1
                )
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button(manager.isRunning ? "Berhenti" : "Mulai") {
                    manager.isRunning ? manager.stop() : manager.start()
                }
                .buttonStyle(.bordered)

                Button("Kalibrasi di sini") {
                    manager.calibrateBaseline()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!manager.isRunning)

                Button("Reset") {
                    manager.resetCalibration()
                }
                .buttonStyle(.bordered)
            }

            instructionText

            Spacer()
        }
        .padding()
        .onDisappear { manager.stop() }
    }

    private var statusIndicator: some View {
        let (color, label): (Color, String) = {
            switch manager.status {
            case .idle:
                return (.gray, "Tempelkan ke area logam yang pasti asli, lalu tekan \"Kalibrasi di sini\"")
            case .likelyBareMetal:
                return (.green, "Kemungkinan logam asli")
            case .possibleFiller:
                return (.orange, "Indikasi dempul / lapisan tebal")
            case .noSignal:
                return (.red, "Sinyal logam lemah / tidak terdeteksi")
            }
        }()
        return VStack(spacing: 8) {
            Circle().fill(color).frame(width: 60, height: 60)
            Text(label)
                .multilineTextAlignment(.center)
                .font(.subheadline)
        }
    }

    private var instructionText: some View {
        Text("""
        Cara pakai:
        1. Tempelkan bagian belakang iPhone serata mungkin ke permukaan body yang diyakini logam asli (mis. pilar A, bawah kap mesin, atau rangka pintu).
        2. Tekan "Kalibrasi di sini" untuk menetapkan nilai referensi.
        3. Geser perlahan ke panel lain dengan jarak & tekanan tempel yang sama persis.
        4. Penurunan signifikan dari referensi bisa mengindikasikan dempul/filler tebal yang menjauhkan sensor dari pelat besi.

        Catatan: lepas case/aksesori bermagnet (termasuk MagSafe) dan jauhkan dari logam lain di sekitar saat mengukur, karena bisa mengganggu pembacaan.
        """)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
}

#Preview {
    MagnetInspectorView()
}
