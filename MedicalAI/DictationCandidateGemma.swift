import Foundation

extension DictationCandidate {
    private static let allowed: [String] = [
        "Reposition", "Tourniquet check", "Wound packing", "Erythema margin marked",
        "Urine volume", "Pain score", "Chest seal check", "Dressing inspection",
        "Unclassified — held as narrative"
    ]

    /// Model output is a proposal. Unknown labels collapse to unclassified.
    init?(raw: String, modelJSON: String) {
        self.raw = raw
        self.structuredByModel = true
        guard let obj = Self.parseJSON(modelJSON) else { return nil }
        let label = (obj["intervention"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        intervention = Self.allowed.first { $0.caseInsensitiveCompare(label) == .orderedSame }
            ?? "Unclassified — held as narrative"
        if let siteVal = obj["site"] as? String {
            let trimmed = siteVal.trimmingCharacters(in: .whitespacesAndNewlines)
            site = (trimmed.isEmpty || trimmed.lowercased() == "null") ? nil : trimmed
        } else {
            site = nil
        }
    }

    private static func parseJSON(_ text: String) -> [String: Any]? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        let slice = String(text[start...end])
        guard let data = slice.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj
    }
}
