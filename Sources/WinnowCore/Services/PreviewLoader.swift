import Foundation
import ImageIO

/// Pictures of photos, fast enough to flick through a shoot.
///
/// Grid and full-screen views use the JPEG preview cameras store inside every
/// RAW: about 30 ms on a Sony a6400 file. Only zooming to 100% decodes the RAW
/// itself, which takes about 750 ms, so it happens one photo at a time.
public final class PreviewLoader: @unchecked Sendable {
    // NSCache is thread-safe, which is what makes this class safe to share.
    public static let shared = PreviewLoader()

    private let previews = NSCache<NSString, CGImage>()
    private let fullSize = NSCache<NSString, CGImage>()

    init() {
        previews.totalCostLimit = 1_000_000_000
        fullSize.countLimit = 3
    }

    /// The preview if it is already loaded, so a view can show it without waiting.
    public func cached(for url: URL, maxPixels: Int) -> CGImage? {
        previews.object(forKey: key(url, maxPixels))
    }

    public func preview(for url: URL, maxPixels: Int) -> CGImage? {
        let key = key(url, maxPixels)
        if let hit = previews.object(forKey: key) { return hit }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        previews.setObject(image, forKey: key, cost: image.bytesPerRow * image.height)
        return image
    }

    /// The whole RAW decoded at full size, for checking focus at 100%.
    public func fullResolution(for url: URL) -> CGImage? {
        let key = url.path as NSString
        if let hit = fullSize.object(forKey: key) { return hit }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 20_000,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        fullSize.setObject(image, forKey: key)
        return image
    }

    private func key(_ url: URL, _ maxPixels: Int) -> NSString {
        "\(url.path)#\(maxPixels)" as NSString
    }
}
