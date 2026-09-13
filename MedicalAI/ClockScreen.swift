import SwiftUI
import CoreHaptics
import UIKit

struct ClockScreen: View {
    @EnvironmentObject var clock: MissionClock
    @EnvironmentObject var ledger: LedgerStore
    @Binding var openCard: String?

    var body: some View {
        FillScroll {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Kicker(text: "Elapsed since point of injury")
                    Text(clock.elapsed)
                        .font(.heavy(80))
                        .foregroundStyle(Ink.text)
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.top, 4)
                    Text(clock.remainingText)
                        .font(.label(15))
                        .foregroundStyle(Ink.body)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rule(strong: true) }

                ForEach(clock.gates) { gate in
                    GateRow(gate: gate) { tap(gate) }
                        .frame(maxHeight: .infinity)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Kicker(text: "Missed checks — a deterioration signal")
                    Text(clock.missedText)
                        .font(.label(15))
                        .foregroundStyle(Ink.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay(alignment: .top) { Rule(strong: true) }
            }
        }
    }

    private func tap(_ gate: Gate) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        if gate.id == "reposition" {
            clock.lastReposition = clock.minute
            ledger.append(minute: clock.minute, name: "Reposition",
                          detail: "Right lateral, from clock prompt", provenance: .casualty)
            return
        }
        openCard = gate.cardID
    }
}

struct GateRow: View {
    let gate: Gate
    let action: () -> Void

    private var tone: Color {
        if gate.locked || gate.overdue { return Ink.accent }
        return Ink.mid
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Rectangle().fill(tone).frame(width: 8)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(gate.name).font(.heavy(20)).foregroundStyle(Ink.text)
                        Spacer(minLength: 10)
                        Text(gate.countdown).font(.heavy(20)).foregroundStyle(tone).monospacedDigit()
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text(gate.citation).font(.label(13)).foregroundStyle(Ink.mid)
                        Spacer(minLength: 10)
                        Text(gate.status.uppercased()).font(.label(12)).tracking(1.0).foregroundStyle(tone)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, minHeight: 88, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rule() }
    }
}

/// Every card ends in an observable OUTCOME, never a step confirmation. The
/// measured failure mode is a casualty declaring success without checking.
struct CardScreen: View {
    @EnvironmentObject var clock: MissionClock
    @EnvironmentObject var ledger: LedgerStore
    @EnvironmentObject var voice: VoiceService
    let card: ProtocolBundle.Card
    let close: () -> Void

    var body: some View {
        ZStack {
            Ink.ground.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Kicker(text: "Outcome gate · blocking", color: Ink.text)
                    Text(card.name).font(.heavy(28)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Ink.accentDeep)

                FillScroll {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(card.citation.uppercased())
                            .font(.label(12)).tracking(1.2).foregroundStyle(Ink.dim)
                        Text(card.question)
                            .font(.heavy(28)).foregroundStyle(Ink.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(card.note)
                            .font(.label(16)).foregroundStyle(Ink.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 12)

                        FieldButton(title: voice.armed
                                    ? (voice.speakingID == card.id ? "Stop reading" : "Read this aloud")
                                    : "Arm voice above to read aloud",
                                    enabled: voice.armed) {
                            voice.speak(id: card.id, text: card.spoken)
                        }
                        Text("Bundle \(ProtocolBundle.version) · \(ProtocolBundle.source)")
                            .font(.label(12)).foregroundStyle(Ink.mid)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(16)
                }

                VStack(spacing: 2) {
                    FieldButton(title: card.affirm, filled: true) { confirm() }
                    FieldButton(title: card.deny) { deny() }
                    Button("Back to clock", action: close)
                        .font(.label(14))
                        .foregroundStyle(Ink.mid)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, 16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func confirm() {
        voice.stopSpeaking()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        switch card.id {
        case "tourniquet":
            clock.tourniquetConverted = true
            ledger.append(minute: clock.minute, name: "Tourniquet converted",
                          detail: "Outcome gate passed: bleeding controlled, pressure dressing applied",
                          provenance: .device, protocolVersion: ProtocolBundle.version)
        case "splint":
            clock.lastSplintCheck = clock.minute
            ledger.append(minute: clock.minute, name: "Splint distal pulse",
                          detail: "Present, right ankle", provenance: .casualty)
        case "vitals":
            clock.lastVitals = clock.minute
            ledger.append(minute: clock.minute, name: "Vitals session",
                          detail: "Self-count HR. Fitbit trend optional. SpO₂ signal lost — not imputed.",
                          provenance: .device)
        case "oral":
            clock.lastOral = clock.minute
            ledger.append(minute: clock.minute, name: "Oral care",
                          detail: "Nursing schedule q12 h completed", provenance: .casualty)
        case "extraction":
            clock.logExtractionAttempt(outcome: "succeeded_or_deferred")
            ledger.append(minute: clock.minute, name: "Extraction attempt",
                          detail: "Logged as succeeded or deferred. Mission clock not reset. Attempts: \(clock.extractionAttempts)",
                          provenance: .casualty)
        case "presence":
            ledger.append(minute: clock.minute, name: "Presence check-in",
                          detail: "Named three things · procedural, not therapy",
                          provenance: .casualty)
        default:
            ledger.append(minute: clock.minute, name: card.name,
                          detail: card.affirm + ". Source conflict displayed to user.",
                          provenance: .protocolAsserted, protocolVersion: ProtocolBundle.version)
        }
        close()
    }

    private func deny() {
        voice.stopSpeaking()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        if card.id == "extraction" {
            clock.logExtractionAttempt(outcome: "failed")
            ledger.append(minute: clock.minute, name: "Extraction attempt failed",
                          detail: "Failed — continue schedule. Clock not reset. Attempts: \(clock.extractionAttempts)",
                          provenance: .casualty)
        } else if card.id == "oral" {
            ledger.append(minute: clock.minute, name: "Oral care deferred",
                          detail: "Cannot complete now · logged without shame",
                          provenance: .casualty)
        } else {
            ledger.append(minute: clock.minute, name: "Outcome not confirmed",
                          detail: "\(card.name): \(card.deny). Added to buddy-contact list.",
                          provenance: .device)
        }
        close()
    }
}
