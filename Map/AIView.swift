//
//  AIView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 03/07/26.
//

import SwiftUI
import FoundationModels
import Translation

// MARK: - Model untuk decode JSON dinamis

enum JSONValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Int.self) { self = .int(v); return }
        if let v = try? container.decode(Double.self) { self = .double(v); return }
        if let v = try? container.decode(Bool.self) { self = .bool(v); return }
        if let v = try? container.decode(String.self) { self = .string(v); return }
        if container.decodeNil() { self = .null; return }
        throw DecodingError.typeMismatch(
            JSONValue.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Tipe tidak dikenali")
        )
    }

    var asInt: Int? {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        default: return nil
        }
    }
}

struct Coordinates: Decodable {
    let lat: Double
    let lng: Double
}

struct LayerData: Decodable {
    let layer: String
    let distance_meters: Double
    let label: String
    let color: String
    let attributes: [String: JSONValue]
    let total: Int?
}

struct LocationInsight: Decodable {
    let success: Bool
    let coordinates: Coordinates
    let data: [LayerData]
}

// MARK: - Konversi JSON -> teks ringkas untuk prompt

enum LocationSummaryBuilder {
    static func buildPromptText(from insight: LocationInsight) -> String {
        var lines: [String] = []
        lines.append("Location coordinates: \(insight.coordinates.lat), \(insight.coordinates.lng)")

        for item in insight.data {
            switch item.layer {
            case "population":
                if let jumlah = item.attributes["jumlah_pen"]?.asInt {
                    lines.append("Population: \(jumlah) people")
                }

            case "public_facilities":
                let category = item.label
                let distance = Int(item.distance_meters)
                lines.append("Nearest public facility (\(category)): \(distance) meters away")

            case "roads_buffer":
                lines.append("Road access - \(item.label)")

            default:
                var line = "\(item.layer): \(item.label)"
                if item.distance_meters > 0 {
                    line += " (\(Int(item.distance_meters)) meters away)"
                }
                lines.append(line)
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - View

func debugSupportedLanguages() {
    let supported = SystemLanguageModel.default.supportedLanguages
    for lang in supported {
        let code = lang.languageCode?.identifier ?? "unknown"
        let region = lang.region?.identifier ?? "-"
        print("- \(code) (\(region))")
    }
}

struct AIView: View {
    @State private var jsonInput: String = ""
    @State private var summary: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @State private var translatedSummary: String?
    @State private var isTranslating = false
    // FIX: triggerTranslation dihapus — tidak pernah dipakai.
    @State private var translationConfig: TranslationSession.Configuration?

    private var isModelAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    private var deviceLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    private var isIndonesianDevice: Bool {
        deviceLanguageCode == "id"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    if !isModelAvailable {
                        Text("Apple Intelligence tidak tersedia di perangkat ini.")
                            .foregroundStyle(.red)
                    }

                    Text("Data JSON (lokal):")
                        .font(.headline)

                    TextEditor(text: $jsonInput)
                        .frame(height: 220)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.system(size: 12, design: .monospaced))

                    Button("Muat Sample Data") {
                        jsonInput = SampleData.locationInsightJSON
                    }
                    .buttonStyle(.bordered)
                    
                    Text("Debug: empty=\(jsonInput.isEmpty), loading=\(isLoading), modelAvail=\(isModelAvailable), isID=\(isIndonesianDevice)")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Button {
                        Task { await summarizeLocationData() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Ringkas Data Lokasi")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    // FIX: disable juga saat model tidak tersedia.
                    .disabled(jsonInput.isEmpty || isLoading || (!isModelAvailable && !isIndonesianDevice))

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    VStack {
                        if !summary.isEmpty {
                            if isTranslating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Menerjemahkan...")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                            } else {
                                Text(translatedSummary ?? summary)
                                    .padding(8)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .translationTask(translationConfig) { session in
                        do {
                            let response = try await session.translate(summary)
                            translatedSummary = response.targetText
                        } catch {
                            print("Translation error: \(error)")
                            // FIX: kalau translate gagal, tampilkan teks Inggris apa adanya.
                            translatedSummary = nil
                        }
                        isTranslating = false
                    }
                }
                .padding()
            }
            .navigationTitle("AI Summarizer")
            .onAppear {
                if jsonInput.isEmpty {
                    jsonInput = SampleData.locationInsightJSON
                }
                debugSupportedLanguages()
            }
        }
    }

    // FIX UTAMA: generator teks bebas (TANPA @Generable / generating:).
    // Guided generation (respond(to:generating:)) memakai constrained decoding yang
    // mengunci output ke Inggris — itu sebabnya permintaan Bahasa Indonesia diabaikan.
    // Dengan respond(to:) biasa, instruksi bahasa dihormati model.
    private func generateNarrative(from promptText: String, inIndonesian: Bool) async throws -> String {
        let languageLine = inIndonesian
            ? "Write the paragraph in Bahasa Indonesia."
            : "Write the paragraph in English."
        let session = LanguageModelSession(
            model: .default,
            instructions: """
            You are an assistant that explains geographic location conditions to a general audience.
            Write a single flowing paragraph (not a list) that weaves together, in this exact order:
            (1) flood risk, (2) temperature, (3) air quality, (4) green spaces, (5) population,
            (6) elevation, (7) road access, (8) nearby public facilities, (9) wifi connectivity,
            (10) mobile data connectivity, (11) crime rate.
            Keep it strictly under 45 words total. Be extremely concise — mention each topic in
            just a few words, not a full sentence. Avoid raw technical terms.
            \(languageLine)
            """
        )
        let result = try await session.respond(to: promptText)
        return result.content
    }
    
    private func summarizeLocationData() async {
        isLoading = true
        errorMessage = nil
        summary = ""
        translatedSummary = nil

        defer { isLoading = false }

        guard let jsonData = jsonInput.data(using: .utf8) else {
            errorMessage = "JSON tidak valid."
            return
        }

        do {
            let insight = try JSONDecoder().decode(LocationInsight.self, from: jsonData)

            if isModelAvailable {
                let promptText = LocationSummaryBuilder.buildPromptText(from: insight)

                if isIndonesianDevice {
                    if let direct = try? await generateNarrative(from: promptText, inIndonesian: true),
                       !direct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        summary = direct
                        return
                    }
                    summary = try await generateNarrative(from: promptText, inIndonesian: false)
                    startTranslation()
                } else {
                    summary = try await generateNarrative(from: promptText, inIndonesian: false)
                }
            } else {
                // FIX: model tidak tersedia → pakai template English (bukan AI),
                // lalu alirkan ke pipeline translasi yang sama seperti summary AI.
                summary = TemplateSummaryGenerator.generate(from: insight)
                if isIndonesianDevice {
                    startTranslation()
                }
            }
        } catch {
            errorMessage = "Gagal memproses data: \(error.localizedDescription)"
        }
    }

    // FIX: pemicu translate yang bisa diulang. Meng-assign config baru dengan nilai
    // yang sama TIDAK memicu ulang .translationTask — harus pakai invalidate().
    private func startTranslation() {
        isTranslating = true
        if translationConfig == nil {
            translationConfig = .init(
                source: .init(identifier: "en"),
                target: .init(identifier: "id")
            )
        } else {
            translationConfig?.invalidate()
        }
    }
}

#Preview {
    AIView()
}
