//
//  Localization.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 08/07/26.
//

//  Tabel string dwibahasa (EN / ID) dengan pergantian bahasa live in-app.
//  View apa pun yang mengamati @AppStorage("appLanguage") — langsung atau via
//  SettingsViewModel.selectedLanguage — otomatis re-render saat bahasa diganti.
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case en
    case id
}

enum LocKey: String {
    // Settings — headers
    case languagePreference, appMode, dataPreferences
    // App mode
    case dark, light, system
    case darkSub, lightSub, systemSub
    // Metric names (dipakai bersama oleh Data Preferences & kartu detail)
    case temperature, floodRisk, airQuality, greenSpaces, roadAccess
    case population, families, elevation
    // Data Preferences — item khusus
    case publicFacilities, crimeData, networkConnectivity
    // Data Preferences — subtitle
    case temperatureSub, floodRiskSub, airQualitySub, greenSpacesSub, roadAccessSub
    case publicFacilitiesSub, populationSub, familiesSub, elevationSub
    case crimeDataSub, networkConnectivitySub
    // Menu (VoiceOver labels)
    case menuLanguage, menuMode, menuData
    // Map
    case searchLocation, mapMode, explore, satellite
    // Splash
    case splashTagline
    // Place detail — chrome
    case openInMaps, overview, details
    case analyzingArea, analyzingParams, summarizing
    // Place detail — section titles
    case secEnvironment, secAccessibilities, secSocial, secGeography, secNetwork
    // Place detail — card titles
    case cardPubFacilities, cardCrimeCase
    case cardWifiDownload, cardWifiUpload, cardCellularDownload, cardCellularUpload
    // Units
    case perYear
}

enum L {
    static let storageKey = "appLanguage"

    /// Bahasa aktif saat ini (fallback "en"). Untuk reaktivitas UI, view tetap
    /// harus mengamati @AppStorage("appLanguage") dan mengoper `lang` eksplisit.
    static var current: String {
        UserDefaults.standard.string(forKey: storageKey) ?? "en"
    }

    /// Terjemahan string UI.
    static func t(_ key: LocKey, _ lang: String = current) -> String {
        let entry = table[key] ?? [:]
        return entry[lang] ?? entry["en"] ?? key.rawValue
    }

    /// Terjemahan NILAI metrik berhingga dari PlaceIntel (mis. "High" → "Tinggi").
    /// Nilai bebas dari API yang tak dikenal dikembalikan apa adanya.
    static func value(_ raw: String, _ lang: String = current) -> String {
        guard lang != "en" else { return raw }
        return valueMap[raw.lowercased()]?[lang] ?? raw
    }

    // MARK: - Tabel string UI
    private static let table: [LocKey: [String: String]] = [
        .languagePreference:   ["en": "Language Preference",  "id": "Preferensi Bahasa"],
        .appMode:              ["en": "App Mode",             "id": "Mode Aplikasi"],
        .dataPreferences:      ["en": "Data Preferences",     "id": "Preferensi Data"],

        .dark:      ["en": "Dark",   "id": "Gelap"],
        .light:     ["en": "Light",  "id": "Terang"],
        .system:    ["en": "System", "id": "Sistem"],
        .darkSub:   ["en": "Make your app mode set to dark",      "id": "Atur mode aplikasi menjadi gelap"],
        .lightSub:  ["en": "Make your app mode set to light",     "id": "Atur mode aplikasi menjadi terang"],
        .systemSub: ["en": "Make your app mode set to automatic", "id": "Atur mode aplikasi menjadi otomatis"],

        .temperature: ["en": "Temperature",  "id": "Suhu"],
        .floodRisk:   ["en": "Flood Risk",   "id": "Risiko Banjir"],
        .airQuality:  ["en": "Air Quality",  "id": "Kualitas Udara"],
        .greenSpaces: ["en": "Green Spaces", "id": "Ruang Hijau"],
        .roadAccess:  ["en": "Road Access",  "id": "Akses Jalan"],
        .population:  ["en": "Population",    "id": "Populasi"],
        .families:    ["en": "Families",      "id": "Keluarga"],
        .elevation:   ["en": "Elevation",     "id": "Elevasi"],

        .publicFacilities:    ["en": "Public Facilities",     "id": "Fasilitas Publik"],
        .crimeData:           ["en": "Crime Data",            "id": "Data Kriminal"],
        .networkConnectivity: ["en": "Network Connectivity",  "id": "Konektivitas Jaringan"],

        .temperatureSub:        ["en": "Display the average temperature",   "id": "Tampilkan suhu rata-rata"],
        .floodRiskSub:          ["en": "Display the risk of flooding",      "id": "Tampilkan risiko banjir"],
        .airQualitySub:         ["en": "Display the air quality level",     "id": "Tampilkan tingkat kualitas udara"],
        .greenSpacesSub:        ["en": "Display green space availability",  "id": "Tampilkan ketersediaan ruang hijau"],
        .roadAccessSub:         ["en": "Display primary road access type",  "id": "Tampilkan tipe akses jalan utama"],
        .publicFacilitiesSub:   ["en": "Display nearby public facilities",  "id": "Tampilkan fasilitas publik terdekat"],
        .populationSub:         ["en": "Display area population count",     "id": "Tampilkan jumlah populasi area"],
        .familiesSub:           ["en": "Display total families in the area","id": "Tampilkan total keluarga di area"],
        .elevationSub:          ["en": "Display geography elevation level", "id": "Tampilkan tingkat elevasi geografi"],
        .crimeDataSub:          ["en": "Display reported criminal cases",   "id": "Tampilkan kasus kriminal terlapor"],
        .networkConnectivitySub:["en": "Display WiFi and Cellular speeds",  "id": "Tampilkan kecepatan WiFi dan Seluler"],

        .menuLanguage: ["en": "Language preference", "id": "Preferensi bahasa"],
        .menuMode:     ["en": "App mode",            "id": "Mode aplikasi"],
        .menuData:     ["en": "Data preferences",    "id": "Preferensi data"],

        .searchLocation: ["en": "Search a location", "id": "Cari lokasi"],
        .mapMode:        ["en": "Map Mode",          "id": "Mode Peta"],
        .explore:        ["en": "Explore",           "id": "Jelajah"],
        .satellite:      ["en": "Satellite",         "id": "Satelit"],

        .splashTagline: ["en": "Consider your property like a professional",
                         "id": "Consider your property like a professional"],

        .openInMaps:      ["en": "Open in maps", "id": "Buka di peta"],
        .overview:        ["en": "Overview",     "id": "Ringkasan"],
        .details:         ["en": "Details",      "id": "Detail"],
        .analyzingArea:   ["en": "Analyzing area...", "id": "Menganalisis area..."],
        .analyzingParams: ["en": "Analyzing property environment parameters...",
                           "id": "Menganalisis parameter lingkungan properti..."],
        .summarizing:     ["en": "Summarizing with Apple Intelligence...",
                           "id": "Merangkum dengan Apple Intelligence..."],

        .secEnvironment:     ["en": "Environment",     "id": "Lingkungan"],
        .secAccessibilities: ["en": "Accessibilities", "id": "Aksesibilitas"],
        .secSocial:          ["en": "Social",          "id": "Sosial"],
        .secGeography:       ["en": "Geography",       "id": "Geografi"],
        .secNetwork:         ["en": "Network",         "id": "Jaringan"],

        .cardPubFacilities:     ["en": "Pub. Facilities",     "id": "Fas. Publik"],
        .cardCrimeCase:         ["en": "Crime Case",          "id": "Kasus Kriminal"],
        .cardWifiDownload:      ["en": "Wifi (Download)",     "id": "Wifi (Unduh)"],
        .cardWifiUpload:        ["en": "Wifi (Upload)",       "id": "Wifi (Unggah)"],
        .cardCellularDownload:  ["en": "Cellular (Download)", "id": "Seluler (Unduh)"],
        .cardCellularUpload:    ["en": "Cellular (Upload)",   "id": "Seluler (Unggah)"],

        .perYear: ["en": "/ yr", "id": "/ thn"],
    ]

    // MARK: - Tabel NILAI metrik (kunci di-lowercase)
    private static let valueMap: [String: [String: String]] = [
        "low":      ["id": "Rendah"],
        "medium":   ["id": "Sedang"],
        "moderate": ["id": "Sedang"],
        "high":     ["id": "Tinggi"],
        "good":     ["id": "Baik"],
        "poor":     ["id": "Buruk"],
        "unhealthy":["id": "Tidak Sehat"],
        "very hot": ["id": "Sangat Panas"],
        "bad": ["id": "Buruk"],

        "cold": ["id": "Dingin"],
        "cool": ["id": "Sejuk"],
        "mild": ["id": "Sejuk"],
        "warm": ["id": "Hangat"],
        "hot":  ["id": "Panas"],

        "dense":  ["id": "Lebat"],
        "sparse": ["id": "Jarang"],
        "none":   ["id": "Tidak Ada"],

        "collector": ["id": "Kolektor"],
        "arterial":  ["id": "Arteri"],
        "local":     ["id": "Lokal"],
        "highway":   ["id": "Jl Raya"],
        "other":    ["id": "Lainnya"],
        "footpath":  ["id": "Jl Setapak"],

        "highland": ["id": "D. Tinggi"],
        "lowland":  ["id": "D. Rendah"],
        "hilly":    ["id": "Berbukit"],

        "school":      ["id": "Sekolah"],
        "hospital":    ["id": "Rumah Sakit"],
        "police":      ["id": "Polisi"],
        "none nearby": ["id": "Tidak ada"],

        "unknown": ["id": "Tidak Diketahui"],
    ]
}
