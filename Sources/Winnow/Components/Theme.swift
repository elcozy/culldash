import SwiftUI
import WinnowCore

/// The one source of colours and sizes in the app (Base × Wise, dark).
/// No view uses a literal colour; they all come from here.
enum Theme {
    static let canvas = Color(hex: 0x0a0a0a)
    static let raised = Color(hex: 0x1f1f1f)
    static let hover = Color(hex: 0x282828)
    static let hairline = Color(hex: 0x2a2a2a)
    static let text = Color.white
    static let muted = Color(hex: 0xafafaf)
    static let subtle = Color(hex: 0x757575)

    /// The single accent (Apple system blue): primary action, selection, focus.
    static let accent = Color(hex: 0x0a84ff)
    /// Text drawn on the accent.
    static let onAccent = Color.white
    /// Keepers. Green for its meaning, not as decoration.
    static let positive = Color(hex: 0x30d158)
    static let negative = Color(hex: 0xff6b57)
    static let warning = Color(hex: 0xffc043)
    static let purple = Color(hex: 0xb18cf7)

    static let controlRadius: CGFloat = 8
    static let floatRadius: CGFloat = 12

    static func color(for label: ColorLabel) -> Color? {
        switch label {
        case .none: nil
        case .red: negative
        case .yellow: warning
        case .green: positive
        case .blue: accent
        case .purple: purple
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}
