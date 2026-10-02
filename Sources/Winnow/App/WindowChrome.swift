import AppKit
import SwiftUI

/// Height of the app's own top bar, which replaces the standard title bar.
let topBarHeight: CGFloat = 52
/// Room left of the top bar's content for the close, minimise and zoom buttons.
let trafficLightInset: CGFloat = 84

/// Makes the window's top the app's own bar: the window can be dragged by
/// any empty space, and the close/minimise/zoom buttons are moved down to
/// sit centred in the 52 pt bar instead of the standard 28 pt title bar.
struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { context.coordinator.attach(to: view.window) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { context.coordinator.attach(to: view.window) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator {
        private weak var window: NSWindow?
        private var observers: [NSObjectProtocol] = []

        func attach(to window: NSWindow?) {
            guard let window, window !== self.window else { return }
            self.window = window
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = NSColor(Theme.canvas)
            // AppKit puts the buttons back on every resize and full-screen
            // change, so they are moved again after each one.
            let names: [Notification.Name] = [
                NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification,
                NSWindow.didExitFullScreenNotification, NSWindow.didBecomeKeyNotification,
            ]
            observers = names.map { name in
                NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.placeButtons() }
                }
            }
            placeButtons()
        }

        /// The buttons live in a 28 pt title-bar strip; it is made as tall as
        /// the app's bar, then the buttons are centred in it.
        private func placeButtons() {
            guard let window, !window.styleMask.contains(.fullScreen),
                let close = window.standardWindowButton(.closeButton),
                let titlebar = close.superview, let container = titlebar.superview
            else { return }
            var frame = container.frame
            frame.size.height = topBarHeight
            frame.origin.y = window.frame.height - topBarHeight
            container.frame = frame
            titlebar.frame = container.bounds
            let kinds: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
            for (index, kind) in kinds.enumerated() {
                guard let button = window.standardWindowButton(kind) else { continue }
                let y = (topBarHeight - button.frame.height) / 2
                button.setFrameOrigin(NSPoint(x: 20 + CGFloat(index) * 20, y: y))
            }
        }
    }
}
