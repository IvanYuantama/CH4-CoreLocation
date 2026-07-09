//
//  PlaceOverviewComposer.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 08/07/26.
//

//  Ringkasan area deterministik dari PlaceIntel — TANPA AI.
//  Selalu tersedia & offline; bahasanya mengikuti pilihan APP, bukan bahasa device.
//  Dipakai sebagai fallback saat Apple Intelligence tak tersedia / gagal / iOS < 26.
//

import Foundation

enum PlaceOverviewComposer {
    static func summary(for intel: PlaceIntel, indonesian: Bool) -> String {
        indonesian ? indonesianSummary(intel) : englishSummary(intel)
    }

    // MARK: - English
    private static func englishSummary(_ i: PlaceIntel) -> String {
        let loc = Locale(identifier: "en_US")
        var parts: [String] = []

        var env: [String] = []
        if i.temperatureLevel != "Unknown" { env.append("a \(i.temperatureLevel.lowercased()) average temperature") }
        if i.airQualityLevel  != "Unknown" { env.append("\(i.airQualityLevel.lowercased()) air quality") }
        if i.floodRisk        != "Unknown" { env.append("\(i.floodRisk.lowercased()) flood risk") }
        if !env.isEmpty { parts.append("This area has " + joinNatural(env, "and") + ".") }

        var access: [String] = []
        if i.greenSpaces != "Unknown" { access.append("\(i.greenSpaces.lowercased()) green space") }
        if i.roadAccess  != "Unknown" { access.append("\(i.roadAccess.lowercased()) road access") }
        if i.facilityCount > 0        { access.append("\(i.facilityCount) public facilities nearby") }
        if !access.isEmpty { parts.append("It offers " + joinNatural(access, "and") + ".") }

        var social: [String] = []
        if let pop = i.population   { social.append("a population of about \(pop.formatted(.number.grouping(.automatic).locale(loc)))") }
        if let crime = i.crimeTotal { social.append("around \(crime) reported cases per year") }
        if !social.isEmpty { parts.append("Socially, it has " + joinNatural(social, "with") + ".") }

        if let wifi = i.wifiDownload, let cell = i.mobileDownload {
            parts.append("Connectivity reaches \(wifi) Mbps Wi-Fi and \(cell) Mbps cellular download.")
        } else if let wifi = i.wifiDownload {
            parts.append("Wi-Fi download reaches \(wifi) Mbps.")
        }

        return parts.isEmpty
            ? "Detailed environmental data for this area is not available yet."
            : parts.joined(separator: " ")
    }

    // MARK: - Bahasa Indonesia
    private static func indonesianSummary(_ i: PlaceIntel) -> String {
        let loc = Locale(identifier: "id_ID")
        func v(_ s: String) -> String { L.value(s, "id").lowercased() }
        var parts: [String] = []

        var env: [String] = []
        if i.temperatureLevel != "Unknown" { env.append("suhu rata-rata \(v(i.temperatureLevel))") }
        if i.airQualityLevel  != "Unknown" { env.append("kualitas udara \(v(i.airQualityLevel))") }
        if i.floodRisk        != "Unknown" { env.append("risiko banjir \(v(i.floodRisk))") }
        if !env.isEmpty { parts.append("Area ini memiliki " + joinNatural(env, "dan") + ".") }

        var access: [String] = []
        if i.greenSpaces != "Unknown" { access.append("ruang hijau \(v(i.greenSpaces))") }
        if i.roadAccess  != "Unknown" { access.append("akses jalan \(v(i.roadAccess))") }
        if i.facilityCount > 0        { access.append("\(i.facilityCount) fasilitas publik di sekitar") }
        if !access.isEmpty { parts.append("Tersedia " + joinNatural(access, "dan") + ".") }

        var social: [String] = []
        if let pop = i.population   { social.append("populasi sekitar \(pop.formatted(.number.grouping(.automatic).locale(loc)))") }
        if let crime = i.crimeTotal { social.append("sekitar \(crime) kasus terlapor per tahun") }
        if !social.isEmpty { parts.append("Secara sosial, terdapat " + joinNatural(social, "dengan") + ".") }

        if let wifi = i.wifiDownload, let cell = i.mobileDownload {
            parts.append("Konektivitas mencapai \(wifi) Mbps Wi-Fi dan \(cell) Mbps seluler.")
        } else if let wifi = i.wifiDownload {
            parts.append("Unduhan Wi-Fi mencapai \(wifi) Mbps.")
        }

        return parts.isEmpty
            ? "Data lingkungan detail untuk area ini belum tersedia."
            : parts.joined(separator: " ")
    }

    // MARK: - Helper
    private static func joinNatural(_ items: [String], _ conj: String) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        case 2: return "\(items[0]) \(conj) \(items[1])"
        default:
            let head = items.dropLast().joined(separator: ", ")
            return "\(head), \(conj) \(items.last!)"
        }
    }
}
