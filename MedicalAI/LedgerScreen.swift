import SwiftUI

struct LedgerScreen: View {
    @EnvironmentObject var ledger: LedgerStore

    var body: some View {
        FillScroll {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ledger").font(.heavy(32)).foregroundStyle(Ink.text)
                    Text("Append-only · \(ledger.entries.count) entries · every time stamp device-generated")
                        .font(.label(13)).foregroundStyle(Ink.mid)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay(alignment: .bottom) { Rule(strong: true) }

                if ledger.reversed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Kicker(text: "Empty")
                        Text("No entries yet. Clock gates and dictation write here.")
                            .font(.label(16)).foregroundStyle(Ink.body)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(16)
                } else {
                    ForEach(ledger.reversed) { entry in
                        HStack(alignment: .top, spacing: 0) {
                            Text(hhmm(entry.minute))
                                .font(.heavy(15)).foregroundStyle(Ink.accent)
                                .monospacedDigit()
                                .frame(width: 78, alignment: .leading)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.name).font(.heavy(17)).foregroundStyle(Ink.text)
                                Text(entry.detail).font(.label(15)).foregroundStyle(Ink.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(provenanceLine(entry).uppercased())
                                    .font(.label(11)).tracking(1.2).foregroundStyle(Ink.mid)
                                    .padding(.top, 2)
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 88, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .overlay(alignment: .bottom) { Rule() }
                    }
                }
            }
        }
    }

    private func provenanceLine(_ e: LedgerEntry) -> String {
        if let v = e.protocolVersion { return "\(e.provenance.display) · bundle \(v)" }
        return e.provenance.display
    }
}
