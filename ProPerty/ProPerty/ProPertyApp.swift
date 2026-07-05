import SwiftUI

@main
struct ProPertyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Bahasa app dipilih DI DALAM app (bukan lewat Settings iOS).
/// Alasan: kalau bahasa app di-set ke Indonesia lewat Settings, Locale proses
/// jadi "id" dan Foundation Models menolak SEMUA request
/// (unsupportedLanguageOrLocale). Dengan toggle internal, locale proses tetap
/// bahasa sistem (didukung model), sedangkan UI dipaksa lewat .environment(\.locale).
enum AppLanguage {
    static let storageKey = "appLanguage"

    static var defaultValue: String {
        Locale.current.language.languageCode?.identifier == "id" ? "id" : "en"
    }

    static var isIndonesian: Bool {
        (UserDefaults.standard.string(forKey: storageKey) ?? defaultValue) == "id"
    }

    /// Lookup string dari lproj bahasa terpilih (pengganti NSLocalizedString,
    /// yang selalu mengikuti locale proses).
    static func string(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: storageKey) ?? defaultValue
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

/// Splash → peta utama.
struct RootView: View {
    @State private var isShowingSplash = true
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.defaultValue

    var body: some View {
        ZStack {
            MainMapView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .id(appLanguage)   // rebuild penuh saat bahasa diganti
                .opacity(isShowingSplash ? 0 : 1)
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.5)) { isShowingSplash = false }
        }
    }
}

// MARK: - Theme

enum Theme {
    /// Indigo utama (warna "Pro", tombol, aksen).
    static let primary = Color(red: 0.23, green: 0.13, blue: 0.91)
    /// Oranye aksen logo.
    static let accent = Color(red: 0.98, green: 0.56, blue: 0.11)
    /// Merah pin lokasi.
    static let pin = Color(red: 0.89, green: 0.22, blue: 0.21)
}

// MARK: - Splash

struct SplashView: View {
    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            LogoMark()
                .frame(width: 130, height: 150)
            (Text("Pro").foregroundColor(Theme.primary) + Text("Perty").foregroundColor(.black))
                .font(.system(size: 40, weight: .heavy, design: .rounded))
            Text("Consider your property like a professional")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
    }
}

/// Logo placeholder: huruf "P" bergaya — batang hitam + kepala indigo ber-outline oranye.
struct LogoMark: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(.black)
                .frame(width: 18, height: 150)
                .offset(x: -30)
            RoundedRectangle(cornerRadius: 30)
                .fill(Theme.primary)
                .frame(width: 66, height: 84)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Theme.accent, lineWidth: 9)
                )
                .offset(x: 14, y: -30)
        }
    }
}

#Preview {
    SplashView()
}
