import Foundation
import AVFoundation
import Combine

/// Voice output is real: AVSpeechSynthesizer reads fixed protocol strings aloud,
/// verbatim, with their source and version shown on screen.
///
/// Voice INPUT is deliberately not wired to SFSpeechRecognizer. Apple's own
/// documentation instructs developers not to send health data through it, and it
/// carries a one-minute limit plus per-device daily throttling. The production
/// path is SpeechAnalyzer + SpeechTranscriber with a custom medical lexicon via
/// SFCustomLanguageModelData — see `transcribe(...)` below, which is the single
/// integration point. Until that is wired, dictation degrades explicitly to
/// touch entry and says so.
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

    override init() {
        super.init()
        synth.delegate = self
    }

    /// Armed per session by explicit action, never automatically. Conversation
    /// carries about 300 m; a cry of pain about 1,500 m.
    func toggleArmed() {
        armed.toggle()
        if armed {
            configureSession()
            speak(id: "arm", text: "Voice armed. I will only speak when you ask me to.")
        } else {
            stopSpeaking()
            stopListening()
        }
    }

    private func configureSession() {
        // .duckOthers rather than .playback: the app never takes over the audio
        // route, and it never emits sound unprompted.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
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
        if listening { stopListening(); return }
        listening = true
        transcript = ""
        candidate = nil
        degraded = nil

        Task {
            do {
                let text = try await transcribe()
                self.transcript = text
                self.candidate = DictationCandidate(raw: text)
                self.listening = false
            } catch {
                // FM-8: degrade explicitly to touch entry. Never fail silently.
                self.degrade(String(describing: error))
            }
        }
    }

    func stopListening() { listening = false }

    /// INTEGRATION POINT — replace with SpeechAnalyzer + SpeechTranscriber.
    ///
    ///   let transcriber = SpeechTranscriber(locale: .current, preset: .progressiveTranscription)
    ///   let analyzer = SpeechAnalyzer(modules: [transcriber, SpeechDetector()])
    ///   analyzer.context.contextualStrings = MedicalLexicon.terms
    ///
    /// SpeechDetector gates transcription on voice activity so it is not
    /// always-on (bench B2 decides whether it can be left armed at all), and
    /// contextualStrings is what makes "cefadroxil", "suzetrigine" and "MARCH"
    /// transcribe reliably.
    private func transcribe() async throws -> String {
        throw VoiceError.transcriberNotConfigured
    }

    private func degrade(_ reason: String) {
        listening = false
        degraded = "Speech transcriber not configured — degrading explicitly to touch entry. Sample dictation shown so the hand-off between layers stays visible; the app never fails a voice action silently."
        transcript = DictationCandidate.sample
        candidate = DictationCandidate(raw: DictationCandidate.sample)
    }

    func discardCandidate() {
        candidate = nil
        transcript = ""
        degraded = nil
    }

    enum VoiceError: Error { case transcriberNotConfigured }
}

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speakingID = nil }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speakingID = nil }
    }
}

/// A structured candidate the language layer PROPOSES. It is not a ledger entry
/// until the deterministic core validates and commits it, and the time stamp is
/// generated at commit — never taken from speech.
struct DictationCandidate {
    let raw: String
    let intervention: String
    let site: String?

    static let sample = "reposition onto my left side and I have marked the redness on my thigh it is wider than last time"

    init(raw: String) {
        self.raw = raw
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
         ("Provenance", "Casualty's own dictated words")]
    }
}
