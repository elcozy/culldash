import AppKit
import SwiftUI
import CullDashCore

/// The culling keys. They are read from the window's key events directly,
/// so they work wherever focus is, and ⌘ shortcuts still reach the menus.
///
///     ← → ↑ ↓   move          Space / Return   grid ↔ full screen
///     P X U     pick, reject, clear            Z   zoom to 100%
///     0–5       stars         6–9   colour label    Esc  back
///     Delete    move to Trash (⌘Z puts it back)     R    reject the rest of a burst
@MainActor
enum KeyCommands {
    static func handle(_ event: NSEvent, store: LibraryStore) -> Bool {
        // Typing in the search field must not flag photos.
        guard store.folder != nil, !(NSApp.keyWindow?.firstResponder is NSText),
            event.modifierFlags.intersection([.command, .control, .option]).isEmpty
        else { return false }

        switch event.keyCode {
        case 123: store.move(by: -1)
        case 124: store.move(by: 1)
        case 126: store.moveRow(-1)
        case 125: store.moveRow(1)
        case 36, 76, 49: store.toggleMode()
        case 53: store.back()
        case 51, 117: Task { await store.trashSelected() }
        default: return handleCharacter(event.charactersIgnoringModifiers?.lowercased().first, store: store)
        }
        return true
    }

    private static func handleCharacter(_ character: Character?, store: LibraryStore) -> Bool {
        guard let character else { return false }
        switch character {
        case "p": store.setFlag(.pick)
        case "x": store.setFlag(.reject)
        case "u": store.setFlag(.none)
        case "z": store.toggleZoom()
        case "g": store.mode = .grid
        case "r": store.rejectRestOfBurst()
        default:
            guard let digit = character.wholeNumberValue else { return false }
            if digit <= 5 {
                store.setRating(digit)
            } else if let label = ColorLabel.forKey(digit) {
                store.setLabel(label)
            } else {
                return false
            }
        }
        return true
    }
}

/// Installs the key handler while the view is on screen.
struct KeyCommandsModifier: ViewModifier {
    let store: LibraryStore
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    let handled = MainActor.assumeIsolated { KeyCommands.handle(event, store: store) }
                    return handled ? nil : event
                }
            }
            .onDisappear {
                if let monitor { NSEvent.removeMonitor(monitor) }
            }
    }
}
