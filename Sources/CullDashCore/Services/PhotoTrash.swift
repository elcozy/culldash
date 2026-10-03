import Foundation

/// A file moved to the Trash, and where it came from, so it can go back.
public struct TrashedFile: Hashable, Sendable {
    public let original: URL
    public let trashed: URL
}

/// Moves photos to the Trash, never deleting outright, so a wrong call can
/// be undone (on an external drive, the Trash is that drive's own).
public enum PhotoTrash {
    /// Trashes the RAW, its JPEG companion and its sidecar together.
    public static func trash(_ photo: Photo) throws -> [TrashedFile] {
        var moved: [TrashedFile] = []
        for url in photo.allFiles + [photo.sidecar] where FileManager.default.fileExists(atPath: url.path) {
            var result: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &result)
            if let trashed = result as URL? { moved.append(TrashedFile(original: url, trashed: trashed)) }
        }
        return moved
    }

    /// Trashes one file, e.g. a clip being replaced by an edited version.
    /// `nil` when there was nothing there to move.
    public static func trash(_ url: URL) throws -> TrashedFile? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        var result: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &result)
        return (result as URL?).map { TrashedFile(original: url, trashed: $0) }
    }

    /// Puts trashed files back where they were.
    public static func restore(_ files: [TrashedFile]) throws {
        for file in files {
            try FileManager.default.moveItem(at: file.trashed, to: file.original)
        }
    }
}
