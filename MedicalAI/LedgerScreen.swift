import SwiftUI

struct LedgerScreen: View {
    @EnvironmentObject var ledger: LedgerStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ledger").font(.heavy(26)).foregroundStyle(Ink.text)
                    Text("Append-only · \(ledger.entries.count) entries · every time stamp device-generated")
                        .font(.label(12)).foregroundStyle(Ink.mid)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay(alignment: .bottom) { Rule(strong: true) }

                ForEach(ledger.reversed) { entry in
                    HStack(alignment: .top, spacing: 0) {
                        Text(hhmm(entry.minute))
                            .font(.heavy(13)).foregroundStyle(Ink.accent)
                            .monospacedDigit()
                            .frame(width: 70, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name).font(.heavy(15)).foregroundStyle(Ink.text)
                            Text(entry.detail).font(.label(13)).foregroundStyle(Ink.body)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(provenanceLine(entry).uppercased())
                                .font(.label(10)).tracking(1.2).foregroundStyle(Ink.mid)
                                .padding(.top, 3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .overlay(alignment: .bottom) { Rule() }
                }
            }
        }
    }

    private func provenanceLine(_ e: LedgerEntry) -> String {
        if let v = e.protocolVersion { return "\(e.provenance.display) · bundle \(v)" }
        return e.provenance.display
    }
}
