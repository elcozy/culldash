import SwiftUI
import CullDashCore

/// A photo's embedded preview, loaded off the main thread. A preview that is
/// already cached shows straight away, so flicking through never flashes.
struct PreviewImage: View {
    let url: URL
    let maxPixels: Int
    @State private var image: CGImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let shown = image ?? PreviewImage.cached(url, maxPixels) {
                Image(decorative: shown, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else if failed {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.subtle)
                    .help("This file has no preview macOS can read")
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task(id: url) {
            image = PreviewImage.cached(url, maxPixels)
            failed = false
            guard image == nil else { return }
            let loaded = await PreviewImage.load(url, maxPixels)
            guard !Task.isCancelled else { return }
            image = loaded?.image
            failed = loaded == nil
        }
    }

    /// The requested size if loaded, else the other size: a thumbnail can
    /// stand in for the big preview for a moment, and the other way round.
    static func cached(_ url: URL, _ maxPixels: Int) -> CGImage? {
        let other = maxPixels == PreviewSize.full ? PreviewSize.thumbnail : PreviewSize.full
        return PreviewLoader.shared.cached(for: url, maxPixels: maxPixels)
            ?? PreviewLoader.shared.cached(for: url, maxPixels: other)
    }

    /// Loads in the background and fills the cache for the next look.
    nonisolated static func load(_ url: URL, _ maxPixels: Int) async -> LoadedImage? {
        await Task.detached(priority: .userInitiated) {
            PreviewLoader.shared.preview(for: url, maxPixels: maxPixels).map(LoadedImage.init)
        }.value
    }
}

/// A decoded picture handed from a background task to a view. CGImage is
/// immutable once made, so passing it between threads is safe.
struct LoadedImage: @unchecked Sendable {
    let image: CGImage
}
