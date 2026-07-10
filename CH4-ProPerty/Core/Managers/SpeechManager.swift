////
////  SpeechManager.swift
////  CH4-ProPerty
////
////  Created by Andhika Satria on 10/07/26.
////
//
//
//import Foundation
//import Speech
//import AVFoundation
//
//@MainActor
//class SpeechManager: ObservableObject {
//    @Published var isRecording = false
//    @Published var recognizedText = ""
//    @Published var errorMessage: String?
//    
//    // 🌟 1. Ubah menjadi 'var' dan berikan default locale awal
//    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private let audioEngine = AVAudioEngine()
//    
//    init() {
//        requestAuthorization()
//    }
//    
//    private func requestAuthorization() {
//        SFSpeechRecognizer.requestAuthorization { authStatus in
//            DispatchQueue.main.async {
//                if authStatus != .authorized {
//                    self.errorMessage = "Izin penggunaan mikrofon atau pengenalan suara ditolak."
//                }
//            }
//        }
//    }
//    
//    // 🌟 2. Tambahkan parameter `languageCode` (misal: "id" atau "en") pada fungsi toggle
//    func toggleRecording(languageCode: String) {
//        if isRecording {
//            stopRecording()
//        } else {
//            do {
//                try startRecording(languageCode: languageCode)
//            } catch {
//                errorMessage = "Gagal memulai perekaman: \(error.localizedDescription)"
//                stopRecording()
//            }
//        }
//    }
//    
//    // 🌟 3. Sesuaikan fungsi startRecording untuk menerima languageCode
//    private func startRecording(languageCode: String) throws {
//        recognitionTask?.cancel()
//        self.recognitionTask = nil
//        
//        // 🌟 4. KUNCI DINAMIS: Ubah locale secara real-time berdasarkan setelan aplikasi
//        let localeIdentifier = (languageCode == "id") ? "id-ID" : "en-US"
//        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
//        
//        // Pastikan speech recognizer tersedia untuk bahasa terpilih
//        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
//            throw NSError(domain: "SpeechManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Pengenal suara tidak tersedia untuk bahasa ini."])
//        }
//        
//        let audioSession = AVAudioSession.sharedInstance()
//        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else {
//            throw NSError(domain: "SpeechManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gagal membuat request."])
//        }
//        
//        recognitionRequest.shouldReportPartialResults = true
//        
//        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
//            var isFinal = false
//            
//            if let result = result {
//                self.recognizedText = result.bestTranscription.formattedString
//                isFinal = result.isFinal
//            }
//            
//            if error != nil || isFinal {
//                self.audioEngine.stop()
//                self.audioEngine.inputNode.removeTap(onBus: 0)
//                self.recognitionRequest = nil
//                self.recognitionTask = nil
//                self.isRecording = false
//            }
//        }
//        
//        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
//        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            self.recognitionRequest?.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        try audioEngine.start()
//        
//        isRecording = true
//        recognizedText = ""
//    }
//    
//    func stopRecording() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        recognitionRequest?.endAudio()
//        isRecording = false
//    }
//}
