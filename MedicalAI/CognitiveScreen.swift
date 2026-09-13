import SwiftUI
import UIKit

/// Timed serial-subtract-3 micro-task. Baseline lives in UserDefaults via
/// MissionClock. No diagnosis labels — latency + correctness only.
struct CognitiveScreen: View {
    @EnvironmentObject var clock: MissionClock
    @EnvironmentObject var ledger: LedgerStore
    let close: () -> Void

    @State private var startValue = 100
    @State private var current = 100
    @State private var step = 0
    @State private var correct = 0
    @State private var startedAt: Date?
    @State private var finished = false
    @State private var latencyMs = 0
    private let totalSteps = 5
    private let timeLimit: TimeInterval = 30

    var body: some View {
        ZStack {
            Ink.ground.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Kicker(text: "Cognitive micro-task · blocking", color: Ink.text)
                    Text("Serial −3").font(.heavy(28)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Ink.accentDeep)

                FillScroll {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("PERSONAL BASELINE ONLY · NO DIAGNOSIS")
                            .font(.label(12)).tracking(1.2).foregroundStyle(Ink.dim)

                        if finished {
                            resultBlock
                        } else {
                            Text("Start at \(startValue). Subtract three each tap. \(totalSteps) steps · \(Int(timeLimit)) s.")
                                .font(.heavy(22)).foregroundStyle(Ink.text)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Current: \(current)")
                                .font(.heavy(48)).foregroundStyle(Ink.text)
                                .monospacedDigit()

                            Text("Step \(min(step + 1, totalSteps)) of \(totalSteps)")
                                .font(.label(15)).foregroundStyle(Ink.body)

                            if let baseline = clock.cognitiveBaselineMs {
                                Text("Baseline on file: \(baseline) ms total. This run stores a delta only.")
                                    .font(.label(14)).foregroundStyle(Ink.mid)
                            } else {
                                Text("First successful run sets your personal baseline.")
                                    .font(.label(14)).foregroundStyle(Ink.mid)
                            }

                            FieldButton(title: "−3  (tap when ready)", filled: true) {
                                tapSubtract()
                            }
                        }

                        Spacer(minLength: 12)
                        Button("Back to clock", action: close)
                            .font(.label(14))
                            .foregroundStyle(Ink.mid)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(16)
                }
            }
        }
        .onAppear {
            startValue = [97, 100, 103, 88, 91].randomElement() ?? 100
            current = startValue
        }
    }

    private var resultBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Run complete")
                .font(.heavy(28)).foregroundStyle(Ink.text)
            Text("Correct \(correct)/\(totalSteps) · latency \(latencyMs) ms")
                .font(.label(16)).foregroundStyle(Ink.body)
            if let baseline = clock.cognitiveBaselineMs, baseline > 0 {
                let delta = latencyMs - baseline
                Text("Delta vs baseline: \(delta >= 0 ? "+" : "")\(delta) ms")
                    .font(.label(15)).foregroundStyle(Ink.mid)
            } else {
                Text("Stored as personal baseline.")
                    .font(.label(15)).foregroundStyle(Ink.mid)
            }
            FieldButton(title: "Commit to ledger & clock", filled: true) {
                commit()
            }
        }
    }

    private func tapSubtract() {
        if startedAt == nil { startedAt = Date() }
        let expected = startValue - 3 * (step + 1)
        let answer = current - 3
        current = answer
        if answer == expected { correct += 1 }
        step += 1
        let elapsed = Date().timeIntervalSince(startedAt ?? Date())
        if step >= totalSteps || elapsed >= timeLimit {
            latencyMs = Int(elapsed * 1000)
            finished = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func commit() {
        let priorBaseline = clock.cognitiveBaselineMs
        clock.recordCognitiveResult(latencyMs: latencyMs, correct: correct, total: totalSteps)
        let baselineNote: String
        if let baseline = priorBaseline {
            baselineNote = "baseline \(baseline) ms · delta \(latencyMs - baseline) ms"
        } else {
            baselineNote = "baseline set \(latencyMs) ms"
        }
        ledger.append(minute: clock.minute, name: "Cognitive check",
                      detail: "Serial−3 · \(correct)/\(totalSteps) · \(latencyMs) ms · \(baselineNote)",
                      provenance: .casualty)
        close()
    }
}
