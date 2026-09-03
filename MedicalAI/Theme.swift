import SwiftUI

/// Dark-field palette. Deep red on near-black: no white surfaces, no animation,
/// nothing that raises the optical signature of the position.
enum Ink {
    static let ground = Color(red: 0.031, green: 0.016, blue: 0.008)   // #080402
    static let raised = Color(red: 0.102, green: 0.024, blue: 0.020)   // #1A0605
    static let rule = Color(red: 0.176, green: 0.039, blue: 0.016)     // #2D0A04
    static let ruleStrong = Color(red: 0.302, green: 0.090, blue: 0.055) // #4D170E
    static let dim = Color(red: 0.486, green: 0.078, blue: 0.020)      // #7C1405
    static let mid = Color(red: 0.620, green: 0.208, blue: 0.149)      // #9E3526
    static let body = Color(red: 1.0, green: 0.592, blue: 0.514)       // #FF9783
    static let text = Color(red: 1.0, green: 0.769, blue: 0.722)       // #FFC4B8
    static let accent = Color(red: 0.925, green: 0.188, blue: 0.075)   // #EC3013
    static let accentDeep = Color(red: 0.682, green: 0.094, blue: 0.0) // #AE1800
}

extension Font {
    /// Archivo is the programme's typeface. Add the .ttf files to the target and
    /// swap these for `.custom("Archivo-...")` to match the design system exactly.
    static func heavy(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }
    static func label(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
}

struct Kicker: View {
    let text: String
    var color: Color = Ink.dim
    var body: some View {
        Text(text.uppercased())
            .font(.label(11))
            .tracking(1.4)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Rule: View {
    var strong: Bool = false
    var body: some View {
        Rectangle()
            .fill(strong ? Ink.ruleStrong : Ink.rule)
            .frame(height: strong ? 2 : 1)
    }
}

/// Flush-left label, zero corner radius, 12 mm minimum target — usable
/// one-handed, gloved, with the dominant hand injured.
struct FieldButton: View {
    let title: String
    var filled: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.heavy(17))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .padding(.horizontal, 16)
                .foregroundStyle(filled ? Ink.ground : Ink.text)
                .background(filled ? Ink.accent : Color.clear)
                .overlay(alignment: .center) {
                    if !filled {
                        Rectangle().stroke(Ink.dim, lineWidth: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
    }
}

/// Fills the remaining screen when content is short; scrolls when it is not.
/// Extra height is absorbed by children that declare `maxHeight: .infinity`.
struct FillScroll<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
        }
    }
}

