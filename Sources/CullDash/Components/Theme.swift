import AppKit
import SwiftUI
import CullDashCore

/// The one source of colours and sizes in the app. Each colour has a
/// light value (warm cream) and a dark one (Base neutrals), and follows the
/// Mac's appearance. No view uses a literal colour; they all come from here.
enum Theme {
    static let canvas = Color(light: 0xf6f1e7, dark: 0x0a0a0a)
    static let raised = Color(light: 0xebe4d6, dark: 0x1f1f1f)
    static let hover = Color(light: 0xe2dac9, dark: 0x282828)
    static let hairline = Color(light: 0xdcd3c1, dark: 0x2a2a2a)
    static let text = Color(light: 0x1d1b17, dark: 0xffffff)
    static let muted = Color(light: 0x5c564c, dark: 0xafafaf)
    static let subtle = Color(light: 0x8a8375, dark: 0x757575)

    /// The single accent (Apple system blue): primary action, selection, focus.
    static let accent = Color(light: 0x007aff, dark: 0x0a84ff)
    /// Text drawn on the accent.
    static let onAccent = Color.white
    /// Keepers. Green for its meaning, not as decoration.
    static let positive = Color(light: 0x28a745, dark: 0x30d158)
    static let negative = Color(light: 0xd93f2b, dark: 0xff6b57)
    static let warning = Color(light: 0xc98a00, dark: 0xffc043)
    static let purple = Color(light: 0x8a5cf0, dark: 0xb18cf7)

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
    /// A colour that switches with the Mac's light or dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
