//
//  MagnetometerManager.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 24/06/26.
//

import Foundation
import CoreMotion
import Combine

/// Mengelola pembacaan sensor magnetometer untuk mendeteksi
/// anomali medan magnet — misalnya lapisan dempul/filler non-logam
/// yang menutupi pelat besi pada body mobil.
///
/// Prinsip fisika: kekuatan medan magnet yang "ditarik" dari pelat besi
/// menurun seiring jarak sensor-ke-besi. Dempul/filler menambah jarak
/// efektif antara sensor dan besi, sehingga pembacaan akan lebih lemah
/// dibanding area logam asli pada jarak/tekanan tempel yang sama.
final class MagnetometerManager: ObservableObject {

    // MARK: - Published state
    @Published var currentMagnitude: Double = 0        // µT, kekuatan medan magnet saat ini (sudah di-smoothing)
    @Published var baselineMagnitude: Double? = nil    // µT, nilai kalibrasi (referensi logam asli)
    @Published var deviationPercent: Double = 0        // % perubahan dari baseline
    @Published var status: ReadingStatus = .idle
    @Published var isRunning: Bool = false

    enum ReadingStatus {
        case idle             // belum dikalibrasi
        case likelyBareMetal  // mendekati / di atas baseline
        case possibleFiller   // signifikan lebih rendah dari baseline
        case noSignal         // medan terlalu lemah, kemungkinan jauh dari logam apapun
    }

    private let motionManager = CMMotionManager()

    // Rata-rata beberapa sampel terakhir agar pembacaan lebih stabil (mengurangi noise tangan bergetar)
    private var recentSamples: [Double] = []
    private let smoothingWindow = 6

    /// Persentase penurunan dari baseline yang dianggap "indikasi dempul".
    /// Bisa disesuaikan pengguna lewat slider di UI. Mulai dari nilai konservatif
    /// dan kalibrasi ulang sesuai karakteristik bodi mobil yang diperiksa.
    var fillerThresholdPercent: Double = 25

    /// Di bawah nilai ini (µT), anggap sensor tidak mendeteksi massa logam yang berarti
    /// (misalnya menempel ke plastik/kaca, bukan body mobil).
    var noSignalThresholdMicroTesla: Double = 5

    func start() {
        guard motionManager.isMagnetometerAvailable else {
            status = .noSignal
            return
        }
        motionManager.magnetometerUpdateInterval = 1.0 / 30.0 // 30 Hz, cukup responsif untuk digenggam tangan
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.process(field: data.magneticField)
        }
        isRunning = true
    }

    func stop() {
        motionManager.stopMagnetometerUpdates()
        isRunning = false
    }

    /// Tetapkan pembacaan saat ini sebagai referensi "logam asli / bare metal".
    /// Lakukan ini sambil menempelkan iPhone ke area yang dipastikan logam terbuka.
    func calibrateBaseline() {
        baselineMagnitude = currentMagnitude
    }

    func resetCalibration() {
        baselineMagnitude = nil
        deviationPercent = 0
        status = .idle
    }

    private func process(field: CMMagneticField) {
        let magnitude = sqrt(field.x * field.x + field.y * field.y + field.z * field.z)

        recentSamples.append(magnitude)
        if recentSamples.count > smoothingWindow {
            recentSamples.removeFirst()
        }
        let smoothed = recentSamples.reduce(0, +) / Double(recentSamples.count)
        currentMagnitude = smoothed

        guard let baseline = baselineMagnitude, baseline > 0 else {
            status = .idle
            return
        }

        let diff = ((smoothed - baseline) / baseline) * 100
        deviationPercent = diff

        if smoothed < noSignalThresholdMicroTesla {
            status = .noSignal
        } else if diff <= -fillerThresholdPercent {
            status = .possibleFiller
        } else {
            status = .likelyBareMetal
        }
    }
}
