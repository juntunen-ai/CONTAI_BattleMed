import Foundation
import Combine

func hhmm(_ minutes: Int) -> String {
    let m = abs(minutes)
    return String(format: "%03d:%02d", m / 60, m % 60)
}

func shortDuration(_ minutes: Int) -> String {
    let m = abs(minutes)
    let h = m / 60
    return h > 0 ? "\(h)h \(String(format: "%02d", m % 60))m" : "\(String(format: "%02d", m % 60))m"
}

struct Gate: Identifiable {
    let id: String
    let name: String
    let citation: String
    let countdown: String
    let status: String
    let overdue: Bool
    let locked: Bool
    /// Sort key in minutes: the most urgent gate is always first.
    let remaining: Int
    /// The protocol card this gate opens, if any.
    let cardID: String?
}

/// Timers, never clock arithmetic. Every gate is a deterministic state machine
/// evaluated in plain code — no arithmetic, comparison or decision passes
/// through the language layer.
@MainActor
final class MissionClock: ObservableObject {
    /// Minutes since point of injury.
    @Published private(set) var minute: Int
    @Published var tourniquetConverted = false
    @Published var lastReposition = 260
    @Published var lastSplintCheck = 20
    @Published var lastVitals = 180
    @Published var lastOral = 0
    @Published var lastCognitive = 0
    @Published var extractionAttempts = 0
    @Published var deadManFired = false

    /// Demo acceleration. Set to 1 for real time.
    @Published var speed = 1

    private var timer: AnyCancellable?
    private let originKey = "mission.origin"
    private let cognitiveBaselineKey = "cognitive.baseline.ms"
    private let cognitiveBaselineSetKey = "cognitive.baseline.set"

    static let holdMinutes = 72 * 60
    static let deadManHours = 4

    init(startHour: Int = 5) {
        let defaults = UserDefaults.standard
        if let saved = defaults.object(forKey: originKey) as? Date {
            // Elapsed survives relaunch, including an unannounced power-off.
            let real = Int(Date().timeIntervalSince(saved) / 60)
            minute = startHour * 60 + 12 + max(0, real)
        } else {
            defaults.set(Date(), forKey: originKey)
            minute = startHour * 60 + 12
        }
        // Seed nursing/psych anchors near mission start for demo unless already advanced.
        lastOral = max(0, minute - 600)
        lastCognitive = max(0, minute - 360)
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.minute += self.speed
            }
    }

    var elapsed: String { hhmm(minute) }
    var remainingText: String {
        "\(shortDuration(max(0, MissionClock.holdMinutes - minute))) of the 72-hour hold remaining · no evacuation assumed"
    }

    /// Battery projection for the demo. In production this reads
    /// UIDevice.batteryLevel; the 72-hour endurance case rests on bench work
    /// which has not been run.
    var batteryPercent: Int { max(4, 96 - Int(Double(minute) * 0.18)) }

    /// Personal cognitive baseline latency in ms, if recorded.
    var cognitiveBaselineMs: Int? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: cognitiveBaselineSetKey) else { return nil }
        return defaults.integer(forKey: cognitiveBaselineKey)
    }

    func recordCognitiveResult(latencyMs: Int, correct: Int, total: Int) {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: cognitiveBaselineSetKey) {
            defaults.set(latencyMs, forKey: cognitiveBaselineKey)
            defaults.set(true, forKey: cognitiveBaselineSetKey)
        }
        lastCognitive = minute
    }

    func logExtractionAttempt(outcome: String) {
        extractionAttempts += 1
        // Failed / deferred attempts do not reset the 72 h mission clock.
        _ = outcome
    }

    var gates: [Gate] {
        var out: [Gate] = []

        if !tourniquetConverted {
            let left = 360 - minute
            if left > 0 {
                out.append(Gate(id: "tourniquet", name: "Tourniquet conversion",
                                citation: "TCCC 01 May 2026",
                                countdown: shortDuration(left),
                                status: left < 90 ? "Window closing" : "Decide before 6 h",
                                overdue: left < 90, locked: false, remaining: left, cardID: "tourniquet"))
            } else {
                // Past 6 h the gate hard-locks. For a lone casualty there is no
                // close monitoring and no laboratory capability, so conversion
                // is not offered as a choice.
                out.append(Gate(id: "tqlock", name: "Tourniquet — locked on",
                                citation: "TCCC · past 6 h", countdown: "LOCKED",
                                status: "Do not remove", overdue: true, locked: true,
                                remaining: -1, cardID: nil))
            }
        }

        let repo = lastReposition + 120 - minute
        out.append(Gate(id: "reposition", name: "Reposition", citation: "JTS CPG ID 70 · q1–2 h",
                        countdown: repo > 0 ? shortDuration(repo) : "OVERDUE " + shortDuration(repo),
                        status: repo > 0 ? "Scheduled" : "Overdue",
                        overdue: repo <= 0, locked: false, remaining: repo, cardID: nil))

        let oral = lastOral + 720 - minute
        out.append(Gate(id: "oral", name: "Oral care", citation: "Nursing · q12 h · KR-08",
                        countdown: oral > 0 ? shortDuration(oral) : "OVERDUE " + shortDuration(oral),
                        status: oral > 0 ? "Scheduled" : "Overdue",
                        overdue: oral <= 0, locked: false, remaining: oral, cardID: "oral"))

        let cognitive = lastCognitive + 420 - minute // ~7 h mid of q6–8 h
        out.append(Gate(id: "cognitive", name: "Cognitive check", citation: "Timed micro-task · q6–8 h",
                        countdown: cognitive > 0 ? shortDuration(cognitive) : "OVERDUE " + shortDuration(cognitive),
                        status: cognitive > 0 ? "Scheduled" : "Overdue",
                        overdue: cognitive <= 0, locked: false, remaining: cognitive, cardID: "cognitive"))

        let splint = lastSplintCheck + 360 - minute
        out.append(Gate(id: "splint", name: "Splint distal pulse", citation: "JTS CPG ID 70 · q6 h",
                        countdown: splint > 0 ? shortDuration(splint) : "OVERDUE " + shortDuration(splint),
                        status: splint > 0 ? "Scheduled" : "Overdue",
                        overdue: splint <= 0, locked: false, remaining: splint, cardID: "splint"))

        let vitals = lastVitals + 300 - minute
        out.append(Gate(id: "vitals", name: "Vitals session", citation: "Foreground, ≤60 s · Fitbit trend",
                        countdown: vitals > 0 ? shortDuration(vitals) : "OVERDUE " + shortDuration(vitals),
                        status: vitals > 0 ? "Scheduled" : "Overdue",
                        overdue: vitals <= 0, locked: false, remaining: vitals, cardID: "vitals"))

        let abx = 1440 - minute
        out.append(Gate(id: "antibiotic", name: "Cefadroxil 1 g PO", citation: "Fixed dose · conflict flagged",
                        countdown: shortDuration(max(0, abx)), status: "Daily · 3-day pouch",
                        overdue: false, locked: false, remaining: abx, cardID: "antibiotic"))

        // Extraction is always available as a log gate (KR-07), not a countdown.
        out.append(Gate(id: "extraction", name: "Extraction attempt",
                        citation: "KR-07 · recurring, not terminal",
                        countdown: extractionAttempts == 0 ? "NONE YET" : "\(extractionAttempts) logged",
                        status: "Log outcome",
                        overdue: false, locked: false, remaining: 99999, cardID: "extraction"))

        return out.sorted { $0.remaining < $1.remaining }
    }

    /// A missed check is itself a clinical signal — arguably the
    /// highest-specificity one available in isolation — so it is surfaced as a
    /// deterioration indicator, not as a reminder.
    var missedText: String {
        let overdue = gates.filter { $0.overdue && !$0.locked }.count
        if overdue == 0 { return "All scheduled checks completed on time." }
        return "\(overdue) check\(overdue == 1 ? "" : "s") overdue. Logged as a deterioration indicator, not as a reminder."
    }
}
