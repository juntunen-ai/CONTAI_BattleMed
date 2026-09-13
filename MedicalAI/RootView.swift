import SwiftUI

struct RootView: View {
    @EnvironmentObject var ledger: LedgerStore
    @EnvironmentObject var clock: MissionClock
    @EnvironmentObject var voice: VoiceService

    @State private var tab = "clock"
    @State private var openCard: String?
    @State private var screenOff = false

    var body: some View {
        ZStack {
            Ink.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                statusBar
                voiceBar
                Rule(strong: true)

                Group {
                    switch tab {
                    case "voice": VoiceScreen()
                    case "ledger": LedgerScreen()
                    case "handover": HandoverScreen()
                    default: ClockScreen(openCard: $openCard)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rule(strong: true)
                tabBar
            }

            if let id = openCard {
                if id == "cognitive" {
                    CognitiveScreen(close: { openCard = nil })
                        .transition(.opacity)
                } else if let card = ProtocolBundle.cards[id] {
                    CardScreen(card: card, close: { openCard = nil })
                        .transition(.opacity)
                }
            }

            if screenOff {
                RestingState { screenOff = false }
            }
        }
        .foregroundStyle(Ink.text)
    }

    private var statusBar: some View {
        HStack {
            Text("T+\(clock.elapsed)").foregroundStyle(Ink.body)
            Spacer()
            Text(voice.armed ? GemmaService.shared.chip : "BATTLEMED 0.1").foregroundStyle(Ink.dim)
            Spacer()
            Text("\(clock.batteryPercent)%").foregroundStyle(Ink.body)
        }
        .font(.label(13))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rule() }
    }

    private var voiceBar: some View {
        HStack(spacing: 0) {
            Button { voice.toggleArmed() } label: {
                Text(voice.armed ? "VOICE ARMED FOR THIS SESSION" : "VOICE OFF — TAP TO ARM")
                    .font(.label(13))
                    .tracking(1.0)
                    .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .leading)
                    .padding(.horizontal, 16)
                    .foregroundStyle(voice.armed ? Color.white : Ink.mid)
                    .background(voice.armed ? Ink.accentDeep : Color.clear)
            }
            .buttonStyle(.plain)

            Text(voice.speakingID != nil ? "SPEAKING" : (voice.listening ? "LISTENING" : (voice.armed ? "ARMED · SILENT" : "SILENT")))
                .font(.label(11))
                .tracking(1.2)
                .foregroundStyle(Ink.mid)
                .frame(width: 128, alignment: .leading)
                .padding(.horizontal, 12)
        }
        .frame(height: 56)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach([("clock", "Clock"), ("voice", "Voice"), ("ledger", "Ledger"), ("handover", "Hand-over")], id: \.0) { id, label in
                Button { tab = id; openCard = nil } label: {
                    Text(label.uppercased())
                        .font(.label(12))
                        .tracking(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(tab == id ? Ink.ground : Ink.mid)
                        .background(tab == id ? Ink.accent : Color.clear)
                }
                .buttonStyle(.plain)
                Rectangle().fill(Ink.rule).frame(width: 1)
            }
            Button { voice.stopSpeaking(); screenOff = true } label: {
                Text("OFF")
                    .font(.label(12))
                    .tracking(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(Ink.dim)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .padding(.bottom, 10)
        .background(Ink.ground)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The resting state is screen off. The screen is never woken autonomously —
/// a phone screen is visible 0.5–2 km from the ground and 1–6 km from the air.
struct RestingState: View {
    let wake: () -> Void
    @State private var faded = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                Kicker(text: "Resting state")
                Text("HAPTIC PROMPT\nGATE DUE")
                    .font(.heavy(22))
                    .foregroundStyle(Ink.accentDeep)
                    .opacity(faded ? 0.25 : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: faded)
                Text("Tap to wake. No sound, no autonomous screen wake.")
                    .font(.label(13))
                    .foregroundStyle(Ink.mid)
                    .padding(.top, 6)
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: wake)
        .onAppear { faded = true }
    }
}
