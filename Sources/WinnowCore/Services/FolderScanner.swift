import Foundation

/// Lists the photos in one folder, pairing RAW and JPEG files that share a
/// name and reading any XMP sidecar already beside them.
public enum FolderScanner {
    public static func scan(_ folder: URL) throws -> [Photo] {
        try scan([folder])
    }

    /// Several folders as one shoot, e.g. every `DCIM/1xxMSDCF` on a card.
    public static func scan(_ folders: [URL]) throws -> [Photo] {
        var groups: [String: [URL]] = [:]
        for folder in folders {
            // `.skipsHiddenFiles` also drops the `._DSC01850.ARW` files macOS
            // leaves on exFAT drives, which are metadata, not photos.
            let urls = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            // Keyed by full path, since cameras reuse names across folders.
            for url in urls where FileKind(url: url) != nil {
                groups[url.deletingPathExtension().path.lowercased(), default: []].append(url)
            }
        }
        return groups.values.compactMap(makePhoto).sorted(by: captureOrder)
    }

    /// The RAW leads when there is one; the camera JPEG rides along with it.
    static func makePhoto(_ files: [URL]) -> Photo? {
        let sorted = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard let primary = sorted.first(where: { FileKind(url: $0) == .raw }) ?? sorted.first,
            let kind = FileKind(url: primary)
        else { return nil }
        let modified = (try? primary.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate ?? .distantPast
        var photo = Photo(
            primary: primary,
            companions: sorted.filter { $0 != primary },
            kind: kind,
            modified: modified
        )
        photo.culling = XMPSidecar.read(photo.sidecar) ?? Culling()
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
