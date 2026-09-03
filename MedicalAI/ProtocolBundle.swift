import Foundation

/// The signed, versioned protocol bundle. In production this ships as a signed
/// data file keyed to a doctrine version, not as source — a doctrine update is
/// then a bundle update rather than an app release. Nothing here is computed.
struct ProtocolBundle {
    static let version = "2026.05.01"
    static let source = "TCCC 01 May 2026 · JTS PCC CPG ID 91"

    struct Card: Identifiable {
        let id: String
        let name: String
        let citation: String
        /// The observable outcome, never a step confirmation.
        let question: String
        let note: String
        let affirm: String
        let deny: String
        /// Read aloud verbatim. Never generated, never paraphrased.
        let spoken: String
    }

    static let cards: [String: Card] = [
        "tourniquet": Card(
            id: "tourniquet",
            name: "Tourniquet conversion",
            citation: "TCCC 01 May 2026 · 2–6 h window",
            question: "Has bleeding stopped and is the distal pulse absent?",
            note: "Self-application succeeds in roughly two thirds of attempts and the commonest error is skipping the pulse check. This asks for the outcome, not for confirmation that you performed a step.",
            affirm: "Bleeding stopped · pulse absent",
            deny: "Not confirmed",
            spoken: "Tourniquet conversion. Convert before two hours. After six hours, do not remove the tourniquet unless close monitoring and laboratory capability are available. You are alone, so the answer is: do not remove it. Check that bleeding has stopped and that the pulse below the tourniquet is absent."
        ),
        "splint": Card(
            id: "splint",
            name: "Splint distal pulse",
            citation: "JTS CPG ID 70 · q6 h conscious",
            question: "Is the pulse present distal to the splint?",
            note: "An outcome you can observe, not a task you can tick. If you cannot find it, the answer is no and the check escalates to the buddy-contact list.",
            affirm: "Pulse present",
            deny: "Cannot find it",
            spoken: "Splint check. Feel for the pulse below the splint. If you cannot find it, answer no. Do not guess."
        ),
        "antibiotic": Card(
            id: "antibiotic",
            name: "Cefadroxil 1 g PO",
            citation: "TCCC 01 May 2026 — conflicts with JTS CPG ID 24 (2021)",
            question: "Take one fixed-dose pouch now.",
            note: "TCCC moved to cefadroxil; the JTS infection-prevention guideline still specifies moxifloxacin. Both are shown with their dates. The application does not resolve the conflict and performs no arithmetic.",
            affirm: "Taken · pouch 2 of 7",
            deny: "Cannot take orally",
            spoken: "Antibiotic. Take one cefadroxil pouch, one gram, by mouth, once daily. This is a fixed dose. No calculation is performed. Note that the joint trauma system infection guideline from twenty twenty-one still specifies moxifloxacin; both sources are shown with their dates, and a clinician decides."
        ),
        "packing": Card(
            id: "packing",
            name: "Wound packing",
            citation: "TCCC 01 May 2026",
            question: "Have you held continuous pressure for three full minutes?",
            note: "Timed by the device, not self-reported. No published study on self-packing exists, so the timer is the only control available.",
            affirm: "Three minutes held",
            deny: "Had to release",
            spoken: "Wound packing. Pack the wound firmly with gauze, working from the deepest point outward. Then hold continuous, hard pressure for three full minutes. The device is timing it. Do not lift your hands to check."
        ),
        "vitals": Card(
            id: "vitals",
            name: "Vitals session",
            citation: "Foreground session · target 60 s",
            question: "Count your pulse for thirty seconds, twice.",
            note: "Blood oxygen is not used clinically and missing signal is never imputed. Loss of signal is recorded as a finding, because signal quality falls exactly as shock develops.",
            affirm: "Session complete",
            deny: "Cannot complete",
            spoken: "Vitals session. Count your pulse for thirty seconds. Then check for a pulse at your wrist and tell me present or absent."
        )
    ]

    /// Fixed doses. A lookup table by design: no weight-based calculation, no
    /// arithmetic, and nothing patient-specific.
    static let fixedDoses: [(String, String, String)] = [
        ("Cefadroxil", "1 g PO once daily", "TCCC 01 May 2026"),
        ("Enoxaparin", "30 mg BD once haemostasis achieved", "JTS CPG ID 36"),
        ("Analgesia", "One pre-portioned pouch per scheduled interval", "TCCC 01 May 2026")
    ]
}
