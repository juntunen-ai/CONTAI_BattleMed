import Foundation
import AVFoundation
import Combine
import Speech

/// Voice output is real: AVSpeechSynthesizer reads fixed protocol strings aloud.
///
/// Voice input uses SpeechAnalyzer + SpeechTranscriber + SpeechDetector (iOS 26),
/// on-device. SFSpeechRecognizer is not used for audio. Until the locale model
/// is installed, or on iOS < 26, dictation degrades explicitly to touch entry.
@MainActor
final class VoiceService: NSObject, ObservableObject {
    @Published private(set) var armed = false
    @Published private(set) var speakingID: String?
    @Published private(set) var listening = false
    @Published private(set) var transcript = ""
    @Published private(set) var candidate: DictationCandidate?
    @Published private(set) var degraded: String?

    private let synth = AVSpeechSynthesizer()
    private var rate: Float = 0.46

    private var engine: AVAudioEngine?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var analyzeTask: Task<Void, Never>?
    private var analyzer: SpeechAnalyzer?

    override init() {
        super.init()
        synth.delegate = self
    }

    /// Armed per session by explicit action, never automatically.
    func toggleArmed() {
        armed.toggle()
        if armed {
            configurePlaybackSession()
            speak(id: "arm", text: "Voice armed. I will only speak when you ask me to.")
        } else {
            stopSpeaking()
            Task { await finishDictation(commit: false) }
        }
    }

    private func configurePlaybackSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func configureRecordSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio,
                                options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)
    }

    func speak(id: String, text: String) {
        guard armed else { return }
        if speakingID == id { stopSpeaking(); return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-US")
        u.rate = rate
        u.pitchMultiplier = 0.95
        u.postUtteranceDelay = 0.1
        speakingID = id
        synth.speak(u)
    }

    func stopSpeaking() {
        synth.stopSpeaking(at: .immediate)
        speakingID = nil
    }

    // MARK: - Dictation

    func toggleListening() {
        guard armed else { return }
        if listening {
            Task { await finishDictation(commit: true) }
            return
        }
        Task { await startDictation() }
    }

    func stopListening() {
        Task { await finishDictation(commit: true) }
    }

    private func startDictation() async {
        transcript = ""
        candidate = nil
        degraded = nil

        do {
            try await startAnalyzerPipeline()
        } catch {
            degrade(error)
        }
    }

    private func startAnalyzerPipeline() async throws {
        guard #available(iOS 26.0, *) else {
            throw VoiceError.requiresiOS26
        }
        guard SpeechTranscriber.isAvailable else {
            throw VoiceError.transcriberUnavailable
        }

        let micOK = await AVAudioApplication.requestRecordPermission()
        guard micOK else { throw VoiceError.microphoneDenied }

        let speechOK = await requestSpeechAuthorization()
        guard speechOK else { throw VoiceError.speechDenied }

        let locale = await preferredLocale()
        let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
        let detector = SpeechDetector()

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            degraded = "Downloading on-device speech model for \(locale.identifier)…"
            do {
                try await request.downloadAndInstall()
                degraded = nil
            } catch {
                throw VoiceError.modelNotInstalled
            }
        }

        try configureRecordSession()

        let context = AnalysisContext()
        context.contextualStrings[.general] = MedicalLexicon.terms
        let analyzer = SpeechAnalyzer(modules: [detector, transcriber])
        try await analyzer.setContext(context)
        self.analyzer = analyzer

        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber, detector]) else {
            throw VoiceError.noUsableFormat
        }

        let engine = AVAudioEngine()
        self.engine = engine
        let input = engine.inputNode
        let micFormat = input.outputFormat(forBus: 0)
        guard let converter = AVAudioConverter(from: micFormat, to: analyzerFormat) else {
            throw VoiceError.noUsableFormat
        }
        converter.primeMethod = .none

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: micFormat) { buffer, _ in
            if let converted = VoiceService.convert(buffer, with: converter, to: analyzerFormat) {
                continuation.yield(AnalyzerInput(buffer: converted))
            }
        }

        engine.prepare()
        try engine.start()
        listening = true

        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    let piece = String(result.text.characters)
                    await MainActor.run {
                        guard let self, self.listening || !piece.isEmpty else { return }
                        if result.isFinal {
                            if self.transcript.isEmpty {
                                self.transcript = piece
                            } else if !self.transcript.hasSuffix(piece) {
                                self.transcript = (self.transcript + " " + piece)
                                    .replacingOccurrences(of: "  ", with: " ")
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } else {
                            // Volatile: show the in-progress hypothesis without committing it.
                            self.transcript = piece
                        }
                    }
                }
            } catch {
                await MainActor.run { self?.degrade(error) }
            }
        }

        analyzeTask = Task { [weak self] in
            do {
                try await analyzer.start(inputSequence: stream)
            } catch {
                await MainActor.run { self?.degrade(error) }
            }
        }
    }

    private func finishDictation(commit: Bool) async {
        listening = false
        inputContinuation?.finish()
        inputContinuation = nil

        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil

        if #available(iOS 26.0, *) {
            await analyzer?.cancelAndFinishNow()
        }
        analyzer = nil
        resultsTask?.cancel()
        analyzeTask?.cancel()
        resultsTask = nil
        analyzeTask = nil

        configurePlaybackSession()

        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if commit, !text.isEmpty {
            if let structured = await GemmaService.shared.structure(text) {
                candidate = structured
            } else {
                candidate = DictationCandidate(raw: text)
            }
        }
    }

    private func preferredLocale() async -> Locale {
        if #available(iOS 26.0, *) {
            let wanted = [Locale(identifier: "en-GB"), Locale(identifier: "en-US"), Locale.current]
            for loc in wanted {
                if let match = await SpeechTranscriber.supportedLocale(equivalentTo: loc) {
                    return match
                }
            }
            if let first = await SpeechTranscriber.supportedLocales.first {
                return first
            }
        }
        return Locale(identifier: "en-GB")
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Audio-thread conversion. Converter is used only from the tap.
    nonisolated private static func convert(
        _ buffer: AVAudioPCMBuffer,
        with converter: AVAudioConverter,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(max(1, ceil(Double(buffer.frameLength) * ratio)))
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var error: NSError?
        var submitted = false
        let status = converter.convert(to: out, error: &error) { _, outStatus in
            if submitted {
                outStatus.pointee = .noDataNow
                return nil
            }
            submitted = true
            outStatus.pointee = .haveData
            return buffer
        }
        guard status != .error, error == nil, out.frameLength > 0 else { return nil }
        return out
    }

    private func degrade(_ error: Error) {
        listening = false
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        inputContinuation?.finish()
        inputContinuation = nil
        let message: String
        if let voiceError = error as? VoiceError {
            message = voiceError.userMessage
        } else {
            message = "Speech analyzer failed — \(error.localizedDescription). Degrading to touch entry. Nothing was sent off the device."
        }
        degraded = message
        candidate = nil
        configurePlaybackSession()
    }

    func discardCandidate() {
        candidate = nil
        transcript = ""
        degraded = nil
    }

    enum VoiceError: Error {
        case transcriberNotConfigured
        case transcriberUnavailable
        case requiresiOS26
        case microphoneDenied
        case speechDenied
        case modelNotInstalled
        case noUsableFormat

        var userMessage: String {
            switch self {
            case .transcriberNotConfigured:
                return "Speech transcriber not configured — degrading to touch entry."
            case .transcriberUnavailable:
                return "On-device SpeechTranscriber is not available on this device. Degrading to touch entry."
            case .requiresiOS26:
                return "SpeechAnalyzer needs iOS 26. Degrading to touch entry."
            case .microphoneDenied:
                return "Microphone permission denied. Enable it in Settings to dictate."
            case .speechDenied:
                return "Speech-recognition permission denied. Enable it in Settings to dictate."
            case .modelNotInstalled:
                return "On-device speech model is not installed and could not be downloaded. Connect to a network once, then retry. Nothing was sent off the device."
            case .noUsableFormat:
                return "No compatible audio format for SpeechAnalyzer. Degrading to touch entry."
            }
        }
    }
}

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speakingID = nil }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speakingID = nil }
    }
}

/// Terms the on-device transcriber should prefer. Not clinical content —
/// vocabulary hints only. The model still must not compute or decide.
enum MedicalLexicon {
    static let terms: [String] = [
        "tourniquet", "cefadroxil", "suzetrigine", "moxifloxacin", "enoxaparin",
        "MARCH", "ATMIST", "TCCC", "packing", "junctional", "axilla",
        "reposition", "splint", "distal pulse", "haemorrhage", "hemorrhage",
        "pressure dressing", "chest seal", "erythema", "pouch"
    ]
}

/// A structured candidate the language layer PROPOSES. It is not a ledger entry
/// until the deterministic core validates and commits it, and the time stamp is
/// generated at commit — never taken from speech.
struct DictationCandidate {
    let raw: String
    let intervention: String
    let site: String?
    let structuredByModel: Bool

    init(raw: String) {
        self.raw = raw
        self.structuredByModel = false
        let s = raw.lowercased()
        let kinds: [(String, String)] = [
            ("reposition", "Reposition"), ("tourniquet", "Tourniquet check"),
            ("packing", "Wound packing"), ("redness", "Erythema margin marked"),
            ("erythema", "Erythema margin marked"), ("urine", "Urine volume"),
            ("pain", "Pain score"), ("seal", "Chest seal check"), ("dressing", "Dressing inspection")
        ]
        let sites: [(String, String)] = [
            ("left thigh", "Left thigh"), ("right thigh", "Right thigh"), ("thigh", "Thigh"),
            ("axilla", "Axilla"), ("chest", "Chest"), ("left side", "Left lateral"),
            ("right side", "Right lateral"), ("arm", "Arm")
        ]
        intervention = kinds.first { s.contains($0.0) }?.1 ?? "Unclassified — held as narrative"
        site = sites.first { s.contains($0.0) }?.1
    }

    var fields: [(String, String)] {
        [("Intervention", intervention),
         ("Site", site ?? "Not stated"),
         ("Time", "Device-generated on commit — not from speech"),
         ("Provenance", "Casualty's own dictated words"),
         ("Structuring", structuredByModel ? "Gemma on-device (proposal only)" : "Keyword fallback")]
    }
}
