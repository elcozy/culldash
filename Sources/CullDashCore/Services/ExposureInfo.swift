import AVFoundation
import Foundation
import ImageIO

/// The shooting details shown under a photo: camera, lens and exposure.
public struct ExposureInfo: Hashable, Sendable {
    public var camera: String?
    public var lens: String?
    public var focalLength: Double?
    public var aperture: Double?
    public var shutter: Double?
    public var iso: Int?
    /// When the shutter fired, to the hundredth of a second when the camera records it.
    public var captured: Date?
    /// Length of a video clip, in seconds.
    public var duration: Double?

    public init(
        camera: String? = nil, lens: String? = nil, focalLength: Double? = nil,
        aperture: Double? = nil, shutter: Double? = nil, iso: Int? = nil, captured: Date? = nil
    ) {
        self.camera = camera
        self.lens = lens
        self.focalLength = focalLength
        self.aperture = aperture
        self.shutter = shutter
        self.iso = iso
        self.captured = captured
    }

    public static func read(_ url: URL) -> ExposureInfo {
        if FileKind(url: url) == .video { return readVideo(url) }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return ExposureInfo() }
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
        return ExposureInfo(
            camera: tiff[kCGImagePropertyTIFFModel] as? String,
            lens: exif[kCGImagePropertyExifLensModel] as? String,
            focalLength: exif[kCGImagePropertyExifFocalLength] as? Double,
            aperture: exif[kCGImagePropertyExifFNumber] as? Double,
            shutter: exif[kCGImagePropertyExifExposureTime] as? Double,
            iso: (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first,
            captured: parseDate(
                exif[kCGImagePropertyExifDateTimeOriginal] as? String,
                subseconds: exif[kCGImagePropertyExifSubsecTimeOriginal] as? String)
        )
    }

    /// A clip's length and size; waited for here, since callers are off the main thread.
    static func readVideo(_ url: URL) -> ExposureInfo {
        let asset = AVURLAsset(url: url)
        let box = DurationBox()
        let done = DispatchSemaphore(value: 0)
        Task.detached {
            box.seconds = try? await asset.load(.duration).seconds
            done.signal()
        }
        done.wait()
        var info = ExposureInfo()
        info.duration = box.seconds
        return info
    }

    /// "1:05" for a clip of 65 seconds.
    public static func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// "ƒ/2.8", "1/160 s", "ISO 400", "25 mm", leaving out what the file lacks.
    public var settings: [String] {
        var parts: [String] = []
        if let duration { parts.append(Self.formatDuration(duration)) }
        if let aperture { parts.append("ƒ/" + Self.trim(aperture)) }
        if let shutter { parts.append(Self.formatShutter(shutter)) }
        if let iso { parts.append("ISO \(iso)") }
        if let focalLength { parts.append("\(Self.trim(focalLength)) mm") }
        return parts
    }

    /// Fast speeds as photographers write them (1/160 s), slow ones in seconds (0.5 s, 2 s).
    public static func formatShutter(_ seconds: Double) -> String {
        guard seconds > 0 else { return "–" }
        if seconds >= 0.3 { return "\(trim(seconds)) s" }
        return "1/\(Int((1 / seconds).rounded())) s"
    }

    /// EXIF dates read "2025:06:01 14:03:22", in the camera's local time,
    /// with fractions of a second in a separate field ("47" = 0.47 s).
    static func parseDate(_ text: String?, subseconds: String?) -> Date? {
        guard let text else { return nil }
        let numbers = text.split(whereSeparator: { $0 == ":" || $0 == " " }).compactMap { Int($0) }
        guard numbers.count == 6 else { return nil }
        let components = DateComponents(
            year: numbers[0], month: numbers[1], day: numbers[2],
            hour: numbers[3], minute: numbers[4], second: numbers[5])
        guard let date = Calendar.current.date(from: components) else { return nil }
        let fraction = subseconds.flatMap { Double("0." + $0.trimmingCharacters(in: .whitespaces)) } ?? 0
        return date.addingTimeInterval(fraction)
    }

    static func trim(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// Carries a clip's length out of an async load; written once, read after the wait.
private final class DurationBox: @unchecked Sendable {
    var seconds: Double?
}
