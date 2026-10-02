import AVFoundation
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
        // About 2,500 grid thumbnails or 140 full previews.
        previews.totalCostLimit = 1_500_000_000
        fullSize.countLimit = 3
    }

    /// The preview if it is already loaded, so a view can show it without waiting.
    public func cached(for url: URL, maxPixels: Int) -> CGImage? {
        previews.object(forKey: key(url, maxPixels))
    }

    public func preview(for url: URL, maxPixels: Int) -> CGImage? {
        let key = key(url, maxPixels)
        if let hit = previews.object(forKey: key) { return hit }
        if FileKind(url: url) == .video {
            guard let frame = Self.videoFrame(url, maxPixels) else { return nil }
            previews.setObject(frame, forKey: key, cost: frame.bytesPerRow * frame.height)
            return frame
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        // The stored preview first: big in RAW files, so this is the fast path.
        // JPEGs (and some RAWs) only store a 160 px thumbnail, which would
        // look pixelated, so then the picture itself is decoded at the size asked.
        var image = thumbnail(source, maxPixels, decodeAlways: false)
        if let found = image, max(found.width, found.height) < min(maxPixels, 1200) * 9 / 10 {
            image = thumbnail(source, maxPixels, decodeAlways: true) ?? found
        }
        guard let image else { return nil }
        previews.setObject(image, forKey: key, cost: image.bytesPerRow * image.height)
        return image
    }

    /// A frame a second into the clip (or its first frame if shorter),
    /// waited for here because callers are already off the main thread.
    static func videoFrame(_ url: URL, _ maxPixels: Int) -> CGImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixels, height: maxPixels)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)
        let box = FrameBox()
        let done = DispatchSemaphore(value: 0)
        generator.generateCGImageAsynchronously(for: CMTime(seconds: 1, preferredTimescale: 600)) { image, _, _ in
            box.image = image
            done.signal()
        }
        done.wait()
        return box.image
    }

    private func thumbnail(_ source: CGImageSource, _ maxPixels: Int, decodeAlways: Bool) -> CGImage? {
        let options: [CFString: Any] = [
            decodeAlways ? kCGImageSourceCreateThumbnailFromImageAlways : kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
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

/// Carries a frame out of AVFoundation's callback; written once, then read
/// after the semaphore, so it is never touched by two threads at once.
private final class FrameBox: @unchecked Sendable {
    var image: CGImage?
}
