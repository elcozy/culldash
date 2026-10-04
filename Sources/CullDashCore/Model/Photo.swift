import Foundation

/// What a file in a shoot folder is, judged by its extension.
public enum FileKind: Hashable, Sendable {
    case raw
    case image
    case video

    static let rawExtensions: Set<String> = [
        "arw", "raf", "cr2", "cr3", "nef", "nrw", "orf", "rw2", "dng", "pef", "srw",
    ]
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "heic", "heif", "png", "tif", "tiff"]
    /// Sony XAVC (.mp4), Fujifilm and iPhone (.mov), AVCHD (.mts).
    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "mts", "m2ts", "avi"]

    public init?(url: URL) {
        self.init(extension: url.pathExtension.lowercased())
    }

    /// From an extension already lowercased, so a directory listing can judge
    /// thousands of files without building a URL for each one.
    public init?(extension ext: String) {
        if Self.rawExtensions.contains(ext) {
            self = .raw
        } else if Self.imageExtensions.contains(ext) {
            self = .image
        } else if Self.videoExtensions.contains(ext) {
            self = .video
        } else {
            return nil
        }
    }
}

/// One frame of a shoot (a photo, or a video clip): its main file (the RAW when there is one), any
/// same-named companions such as the camera's JPEG, and what was decided.
public struct Photo: Identifiable, Hashable, Sendable {
    public let primary: URL
    public let companions: [URL]
    public let kind: FileKind
    public let modified: Date
    /// Bytes of the main file, for spotting duplicates without reading them.
    public let size: Int64
    public var culling: Culling
    /// The camera model out of EXIF, e.g. "ILCE-6400A". Reading it means
    /// opening the file, which on a card or a hard drive is slow enough that
    /// it is filled in by the background pass that loads thumbnails rather
    /// than when the shoot opens; until then it is nil.
    public var camera: String?

    public init(
        primary: URL, companions: [URL] = [], kind: FileKind, modified: Date,
        size: Int64 = 0, culling: Culling = Culling(), camera: String? = nil
    ) {
        self.primary = primary
        self.companions = companions
        self.kind = kind
        self.modified = modified
        self.size = size
        self.culling = culling
        self.camera = camera
    }

    public var id: URL { primary }
    public var name: String { primary.lastPathComponent }

    /// `DSC01850.xmp` beside `DSC01850.ARW`: the name Bridge and Lightroom look for.
    public var sidecar: URL { primary.deletingPathExtension().appendingPathExtension("xmp") }

    /// Every file that belongs to this frame, so a reject leaves nothing behind.
    public var allFiles: [URL] { [primary] + companions }
}
