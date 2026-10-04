import AppKit
import SwiftUI

/// Hands the photos in view to the Mac's own share menu: AirDrop, Messages,
/// Mail, Photos, whatever else is installed.
///
/// A RAW goes with its camera JPEG, the way they travel together everywhere
/// else in the app, so nothing is quietly left behind.
struct ShareButton: View {
    let urls: [URL]
    @State private var anchor = ShareAnchor()

    var body: some View {
        IconButton(symbol: "square.and.arrow.up", help: help, enabled: !urls.isEmpty) {
            anchor.show(urls)
        }
        // The menu has to hang off a real AppKit view, and SwiftUI has none to
        // offer, so an empty one rides along behind the button.
        .background(SharePresenter(anchor: anchor).frame(width: 1, height: 1))
    }

    private var help: String {
        urls.isEmpty ? "Nothing to share" : "Share — AirDrop, Messages, Mail…"
    }
}

/// Keeps hold of the view the share menu is shown from.
@MainActor
final class ShareAnchor {
    weak var view: NSView?

    func show(_ urls: [URL]) {
        guard let view, !urls.isEmpty else { return }
        let picker = NSSharingServicePicker(items: urls)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}

private struct SharePresenter: NSViewRepresentable {
    let anchor: ShareAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        anchor.view = view
    }
}
