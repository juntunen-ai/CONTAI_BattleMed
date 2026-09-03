import SwiftUI

struct VoiceScreen: View {
    @EnvironmentObject var voice: VoiceService
    @EnvironmentObject var ledger: LedgerStore
    @EnvironmentObject var clock: MissionClock

    var body: some View {
        FillScroll {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Voice").font(.heavy(32)).foregroundStyle(Ink.text)
                    Text("Gemma, on-device · 2 B parameters at 4-bit · weights loaded locally, no network")
                        .font(.label(12)).foregroundStyle(Ink.mid)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay(alignment: .bottom) { Rule(strong: true) }

                firewall
                    .padding(16)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .overlay(alignment: .bottom) { Rule(strong: true) }

                VStack(alignment: .leading, spacing: 0) {
                    Kicker(text: "Instructions read aloud — verbatim, attributed")
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 6)

                    ForEach(["tourniquet", "packing", "antibiotic"], id: \.self) { id in
                        if let card = ProtocolBundle.cards[id] {
                            SpeakableRow(card: card)
                        }
                    }
                }

                dictation
                    .padding(16)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .overlay(alignment: .top) { Rule(strong: true) }
            }
        }
    }

    /// The calculation firewall, stated on screen because it is the safety case.
    private var firewall: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Kicker(text: "Language layer")
                Text("Structures dictation, extracts entities, reads a fixed protocol card aloud. May not compute, compare, decide, or originate clinical content.")
                    .font(.label(14)).foregroundStyle(Ink.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .overlay(alignment: .bottom) { Rule() }

            VStack(alignment: .leading, spacing: 4) {
                Kicker(text: "Deterministic core")
                Text("Timers, gate evaluation, fixed-dose tables, every ledger write. Plain Swift, unit-tested. No arithmetic reaches the model.")
                    .font(.label(14)).foregroundStyle(Ink.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
        }
        .overlay { Rectangle().stroke(Ink.dim, lineWidth: 2) }
    }

    private var dictation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Kicker(text: "Dictate a ledger entry")

            FieldButton(title: voice.armed
                        ? (voice.listening ? "Listening — tap to stop" : "Dictate entry")
                        : "Arm voice above to dictate",
                        filled: voice.listening,
                        enabled: voice.armed) {
                voice.toggleListening()
            }

            if let degraded = voice.degraded {
                VStack(alignment: .leading, spacing: 5) {
                    Kicker(text: "Degraded capability", color: Ink.accent)
                    Text(degraded).font(.label(14)).foregroundStyle(Ink.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .overlay { Rectangle().stroke(Ink.accent, lineWidth: 2) }
            }

            if !voice.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Kicker(text: voice.degraded == nil ? "Raw transcript — the casualty's own words" : "Sample transcript — transcriber not configured",
                           color: Ink.mid)
                    HStack(spacing: 12) {
                        Rectangle().fill(Ink.dim).frame(width: 4)
                        Text(voice.transcript).font(.label(16)).foregroundStyle(Ink.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let candidate = voice.candidate {
                candidatePanel(candidate)
            }

            Text("Whispered speech is unsupported — no platform interface exposes it, and models trained on normal speech degrade. The low-signature answer is a throat or bone-conduction microphone, which is a hardware line item. Voice is armed per session by hand and never auto-activated.")
                .font(.label(13)).foregroundStyle(Ink.mid)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func candidatePanel(_ candidate: DictationCandidate) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "Structured candidate — proposed, not committed", color: .white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Ink.accentDeep)

            ForEach(candidate.fields, id: \.0) { key, value in
                HStack(alignment: .top, spacing: 10) {
                    Text(key.uppercased()).font(.label(11)).tracking(0.8)
                        .foregroundStyle(Ink.mid).frame(width: 96, alignment: .leading)
                    Text(value).font(.label(14)).foregroundStyle(Ink.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .overlay(alignment: .bottom) { Rule() }
            }

            VStack(spacing: 2) {
                FieldButton(title: "Commit — deterministic core writes it", filled: true) {
                    ledger.append(minute: clock.minute,
                                  name: candidate.intervention,
                                  detail: (candidate.site.map { "\($0) · " } ?? "") + "“\(candidate.raw)”",
                                  provenance: .dictated)
                    voice.discardCandidate()
                }
                FieldButton(title: "Discard") { voice.discardCandidate() }
            }
            .padding(12)
        }
        .overlay { Rectangle().stroke(Ink.accentDeep, lineWidth: 2) }
    }
}

struct SpeakableRow: View {
    @EnvironmentObject var voice: VoiceService
    let card: ProtocolBundle.Card

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(card.name).font(.heavy(16)).foregroundStyle(Ink.text)
            Text(card.spoken).font(.label(13)).foregroundStyle(Ink.body)
                .fixedSize(horizontal: false, vertical: true)
            Text("Verbatim · \(card.citation) · bundle \(ProtocolBundle.version)".uppercased())
                .font(.label(10)).tracking(1.0).foregroundStyle(Ink.mid)
            Button {
                voice.speak(id: card.id, text: card.spoken)
            } label: {
                Text(voice.armed ? (voice.speakingID == card.id ? "STOP" : "READ ALOUD") : "VOICE OFF FOR THIS SESSION")
                    .font(.label(13)).tracking(1.0)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .padding(.horizontal, 14)
                    .foregroundStyle(Ink.accent)
                    .overlay { Rectangle().stroke(Ink.dim, lineWidth: 2) }
            }
            .buttonStyle(.plain)
            .opacity(voice.armed ? 1 : 0.45)
            .disabled(!voice.armed)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .overlay(alignment: .bottom) { Rule() }
    }
}
