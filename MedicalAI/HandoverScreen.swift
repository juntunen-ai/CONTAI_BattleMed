import SwiftUI
import CoreImage.CIFilterBuiltins

struct HandoverScreen: View {
    @EnvironmentObject var ledger: LedgerStore
    @EnvironmentObject var clock: MissionClock
    @EnvironmentObject var voice: VoiceService

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Handover").font(.heavy(26)).foregroundStyle(Ink.text)
                    Text("DD Form 1380 · ATMIST · renders with no model, no watch, no network")
                        .font(.label(12)).foregroundStyle(Ink.mid)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay(alignment: .bottom) { Rule(strong: true) }

                if clock.deadManFired {
                    Text("Dead-man trigger fired at T+\(clock.elapsed). Ledger frozen.")
                        .font(.heavy(14)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.vertical, 13)
                        .background(Ink.accentDeep)
                }

                atmistPanel.padding(16)

                FieldButton(title: voice.armed
                            ? (voice.speakingID == "packet" ? "Stop reading" : "Read packet to the medic")
                            : "Arm voice above to read the packet",
                            enabled: voice.armed) {
                    voice.speak(id: "packet", text: spokenPacket)
                }
                .padding(.horizontal, 16)

                // Screen is the primary path: a medic with no app and no network
                // must be able to read it. The code is the machine-ingest path.
                HStack(alignment: .top, spacing: 14) {
                    qrImage
                        .frame(width: 130, height: 130)
                        .background(Ink.ground)
                    Text("Compact offline payload — NATO AMedP-5.1 / STANAG 2231. No cloud, no pairing, no account.")
                        .font(.label(13)).foregroundStyle(Ink.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                buddyList
                    .padding(16)
                    .overlay(alignment: .top) { Rule(strong: true) }

                FieldButton(title: "Simulate dead-man trigger") {
                    clock.deadManFired = true
                    ledger.append(minute: clock.minute, name: "Dead-man trigger",
                                  detail: "No interaction for \(MissionClock.deadManHours) h. Ledger frozen into handover state.",
                                  provenance: .device)
                }
                .padding(16)
            }
        }
    }

    private var atmist: [(String, String)] {
        [("Age / sex", "31 · M · callsign withheld in packet"),
         ("Time", "Injury T0 · packet rendered T+\(clock.elapsed)"),
         ("Mechanism", "Fragmentation, right thigh and left axilla"),
         ("Injuries", "Right femoral haemorrhage, tourniquet \(clock.tourniquetConverted ? "converted" : "in situ from T+000:04"); packed axillary wound"),
         ("Signs", "HR 124, RR 26, radial present. SpO₂ unavailable — signal lost, not imputed."),
         ("Treatment", "\(ledger.entries.count) logged interventions, all device-time-stamped. Fixed doses per \(ProtocolBundle.source).")]
    }

    private var atmistPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "ATMIST", color: Ink.text)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Ink.dim)
            ForEach(atmist, id: \.0) { key, value in
                HStack(alignment: .top, spacing: 8) {
                    Text(key.uppercased()).font(.label(11)).tracking(0.8)
                        .foregroundStyle(Ink.mid).frame(width: 86, alignment: .leading)
                    Text(value).font(.label(14)).foregroundStyle(Ink.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .overlay(alignment: .bottom) { Rule() }
            }
        }
        .overlay { Rectangle().stroke(Ink.dim, lineWidth: 2) }
    }

    private var buddyList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "Buddy-contact list — 60 seconds, best use first")
                .padding(.bottom, 10)
            ForEach(Array(buddyItems.enumerated()), id: \.offset) { i, item in
                HStack(alignment: .top, spacing: 0) {
                    Text("\(i + 1)").font(.heavy(14)).foregroundStyle(Ink.accent)
                        .frame(width: 24, alignment: .leading)
                    Text(item).font(.label(14)).foregroundStyle(Ink.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 9)
                .overlay(alignment: .bottom) { Rule() }
            }
        }
    }

    private let buddyItems = [
        "Verify or redo the lower-limb tourniquet — largest measured self-versus-buddy gap",
        "The conversion decision inside the 2–6 h window",
        "Inspect what the casualty cannot see: back, posterior thigh, sacrum, scalp, axilla",
        "Junctional packing needing three minutes of two-handed pressure",
        "Take the handover record out, even if the casualty stays"
    ]

    private var spokenPacket: String {
        "Handover. Thirty-one year old male. Fragmentation injury, right thigh and left axilla. Right femoral haemorrhage with a tourniquet \(clock.tourniquetConverted ? "converted" : "in place since four minutes after injury"), and a packed axillary wound. Heart rate one hundred twenty-four, respiratory rate twenty-six, radial pulse present. Blood oxygen unavailable: the signal was lost and has not been estimated. \(ledger.entries.count) interventions are logged, every one with a device time stamp."
    }

    /// Compact payload, generated locally. Nothing is transmitted.
    private var qrImage: some View {
        let payload = atmist.map { "\($0.0)=\($0.1)" }.joined(separator: "|")
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return AnyView(Color.clear) }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return AnyView(Color.clear) }
        return AnyView(
            Image(decorative: cg, scale: 1)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .colorMultiply(Ink.text)
        )
    }
}
