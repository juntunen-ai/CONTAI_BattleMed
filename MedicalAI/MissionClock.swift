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
    @Published var deadManFired = false

    /// Demo acceleration. Set to 1 for real time.
    @Published var speed = 1

    private var timer: AnyCancellable?
    private let originKey = "mission.origin"

    static let holdMinutes = 168 * 60
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
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.minute += self.speed
            }
    }

    var elapsed: String { hhmm(minute) }
    var remainingText: String {
        "\(shortDuration(max(0, MissionClock.holdMinutes - minute))) of the 168-hour hold remaining · no evacuation assumed"
    }

    /// Battery projection for the demo. In production this reads
    /// UIDevice.batteryLevel; the 168-hour endurance case rests on bench B1,
    /// which has not been run.
    var batteryPercent: Int { max(4, 96 - Int(Double(minute) * 0.075)) }

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

        let splint = lastSplintCheck + 360 - minute
        out.append(Gate(id: "splint", name: "Splint distal pulse", citation: "JTS CPG ID 70 · q6 h",
                        countdown: splint > 0 ? shortDuration(splint) : "OVERDUE " + shortDuration(splint),
                        status: splint > 0 ? "Scheduled" : "Overdue",
                        overdue: splint <= 0, locked: false, remaining: splint, cardID: "splint"))

        let vitals = lastVitals + 300 - minute
        out.append(Gate(id: "vitals", name: "Vitals session", citation: "Foreground, ≤60 s",
                        countdown: vitals > 0 ? shortDuration(vitals) : "OVERDUE " + shortDuration(vitals),
                        status: vitals > 0 ? "Scheduled" : "Overdue",
                        overdue: vitals <= 0, locked: false, remaining: vitals, cardID: "vitals"))

        let abx = 1440 - minute
        out.append(Gate(id: "antibiotic", name: "Cefadroxil 1 g PO", citation: "Fixed dose · conflict flagged",
                        countdown: shortDuration(max(0, abx)), status: "Daily",
                        overdue: false, locked: false, remaining: abx, cardID: "antibiotic"))

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
