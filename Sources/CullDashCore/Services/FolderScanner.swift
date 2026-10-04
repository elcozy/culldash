import Foundation

/// Lists the photos in one folder, pairing RAW and JPEG files that share a
/// name and reading any XMP sidecar already beside them.
public enum FolderScanner {
    public static func scan(_ folder: URL) throws -> [Photo] {
        try scan([folder])
    }

    /// Several folders as one shoot, e.g. every `DCIM/1xxMSDCF` on a card.
    public static func scan(_ folders: [URL]) throws -> [Photo] {
        var groups: [String: [DirectoryEntry]] = [:]
        // Which photos have a sidecar, so the other thousands are never opened
        // looking for one that was never written.
        var sidecars: Set<String> = []
        for folder in folders {
            // The listing leaves out hidden files, which on an exFAT card also
            // drops the `._DSC01850.ARW` companions macOS writes beside every
            // file: metadata, not photos.
            for entry in try DirectoryListing.entries(of: folder) where !entry.isDirectory {
                // Keyed by folder and name, since cameras reuse names across folders.
                let key = "\(folder.path)/\(entry.stem)"
                if entry.fileExtension == "xmp" {
                    sidecars.insert(key)
                } else if FileKind(extension: entry.fileExtension) != nil {
                    groups[key, default: []].append(entry)
                }
            }
        }
        return groups.compactMap { makePhoto($0.value, hasSidecar: sidecars.contains($0.key)) }
            .sorted(by: captureOrder)
    }

    /// The RAW leads when there is one; the camera JPEG rides along with it.
    static func makePhoto(_ files: [DirectoryEntry], hasSidecar: Bool) -> Photo? {
        let sorted = files.sorted { $0.name < $1.name }
        // A RAW leads its JPEG; a still leads the clip of an iPhone Live Photo.
        guard let primary = sorted.first(where: { FileKind(extension: $0.fileExtension) == .raw })
            ?? sorted.first(where: { FileKind(extension: $0.fileExtension) == .image }) ?? sorted.first,
            let kind = FileKind(extension: primary.fileExtension)
        else { return nil }
        var photo = Photo(
            primary: primary.url,
            companions: sorted.filter { $0.url != primary.url }.map(\.url),
            kind: kind,
            modified: primary.modified,
            size: primary.size
        )
        if hasSidecar { photo.culling = XMPSidecar.read(photo.sidecar) ?? Culling() }
        return photo
    }

    /// Cameras stamp each file when it is shot and copying keeps that date, so
    /// sorting by it interleaves frames from two cameras in the order they
    /// were taken. The name breaks ties within a burst.
    public static func captureOrder(_ a: Photo, _ b: Photo) -> Bool {
        if a.modified != b.modified { return a.modified < b.modified }
        return a.name.localizedStandardCompare(b.name) == .orderedAscending
    }
}
