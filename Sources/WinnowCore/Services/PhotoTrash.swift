import Foundation

/// Moves rejected photos to the Trash, never deleting outright, so a wrong
/// call can be undone from the Trash (on an external drive, its own Trash).
public enum PhotoTrash {
    /// Trashes the RAW, its JPEG companion and its sidecar together.
    public static func trash(_ photo: Photo) throws {
        for url in photo.allFiles + [photo.sidecar] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }
    }
}
