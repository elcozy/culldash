import SwiftUI

/// The kinds of button in the app.
enum ButtonTone {
    /// The one main action on screen, in the accent.
    case primary
    case secondary
    case ghost
    case danger
}

/// 8 pt corners, never pill-shaped, coloured by tone.
struct ToneButtonStyle: ButtonStyle {
    let tone: ButtonTone
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    init(_ tone: ButtonTone) { self.tone = tone }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .frame(height: 30)
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: Theme.controlRadius))
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
            .onHover { hovering = $0 }
    }

    private var foreground: Color {
        switch tone {
        case .primary: Theme.onAccent
        case .secondary, .ghost: Theme.text
        case .danger: Theme.negative
        }
    }

    private func background(pressed: Bool) -> Color {
        let lit = (hovering || pressed) && isEnabled
        switch tone {
        case .primary: return lit ? Theme.accent.opacity(0.85) : Theme.accent
        case .secondary: return lit ? Theme.hover : Theme.raised
        case .ghost: return lit ? Theme.raised : .clear
        case .danger: return lit ? Theme.negative.opacity(0.18) : Theme.negative.opacity(0.1)
        }
    }
}

/// A square icon-only button. `help` is its hover label, which every
/// icon-only control needs.
struct IconButton: View {
    let symbol: String
    let help: String
    var active = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
                .foregroundStyle(active ? Theme.onAccent : Theme.text)
                .background(active ? Theme.accent : .clear, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
