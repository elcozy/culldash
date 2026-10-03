import Foundation

/// What kind of place a storage location is, for its icon.
public enum StorageKind: Hashable, Sendable {
    /// A memory card, including one in the Mac's own SD slot.
    case card
    /// An external SSD or hard drive.
    case drive
    /// A folder on this Mac, such as Pictures.
    case mac
}

/// A drive, or a place on this Mac, that shoots can be opened from.
public struct StorageLocation: Identifiable, Hashable, Sendable {
    public let url: URL
    public let name: String
    public let kind: StorageKind
    public let available: Int64?
    public let total: Int64?

    public var id: URL { url }
}

/// A folder holding photos, found inside a storage location.
public struct ShootFolder: Identifiable, Hashable, Sendable {
    public let url: URL
    /// The path from the drive, e.g. "DCIM/100MSDCF".
    public let path: String
    public let photoCount: Int
    public let videoCount: Int

    public var id: URL { url }
}

/// Lists the drives plugged in and finds the folders on them that hold
/// photos, so a shoot opens with two clicks instead of a file dialog.
public enum StorageScanner {
    /// External drives first (memory cards, SSDs, hard drives), then Pictures on this Mac.
    public static func locations() -> [StorageLocation] {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeIsInternalKey, .volumeIsBrowsableKey, .volumeIsRemovableKey,
            .volumeIsEjectableKey, .volumeIsRootFileSystemKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey,
        ]
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        var found: [StorageLocation] = volumes.compactMap { url in
            // A card in the Mac's SD slot reports itself as internal, so a
            // drive counts if it is external, removable or ejectable.
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                values.volumeIsBrowsable == true, values.volumeIsRootFileSystem != true,
                values.volumeIsInternal == false || values.volumeIsRemovable == true || values.volumeIsEjectable == true
            else { return nil }
            let isCard = values.volumeIsRemovable == true && values.volumeIsEjectable != false
                && FileManager.default.fileExists(atPath: url.appendingPathComponent("DCIM").path)
            let space = freeSpace(at: url)
            return StorageLocation(
                url: url,
                name: values.volumeName ?? url.lastPathComponent,
                kind: isCard ? .card : .drive,
                available: space.available ?? values.volumeAvailableCapacity.map(Int64.init),
                total: space.total ?? values.volumeTotalCapacity.map(Int64.init)
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let places: [(FileManager.SearchPathDirectory, String)] = [
            (.picturesDirectory, "Pictures"), (.moviesDirectory, "Movies"),
            (.desktopDirectory, "Desktop"), (.downloadsDirectory, "Downloads"),
        ]
        for (directory, name) in places {
            if let url = FileManager.default.urls(for: directory, in: .userDomainMask).first {
                found.append(StorageLocation(url: url, name: name, kind: .mac, available: nil, total: nil))
            }
        }
        return found
    }

    /// The same drives with their free space brought up to date.
    ///
    /// Used by the start screen's refresh, which runs every few seconds.
    /// `locations()` is not used for that: it looks inside each volume for a
    /// DCIM folder to tell a camera card from a drive, and reading inside a
    /// removable volume is exactly what macOS asks permission for. Doing that
    /// on a timer put the permission sheet back on screen every few seconds
    /// until it was granted. Free space comes from the file system itself,
    /// which needs no permission, so the poll stays on this side of the line.
    public static func updatingSpace(_ locations: [StorageLocation]) -> [StorageLocation] {
        locations.map { location in
            guard location.kind != .mac else { return location }
            let space = freeSpace(at: location.url)
            return StorageLocation(
                url: location.url, name: location.name, kind: location.kind,
                available: space.available ?? location.available,
                total: space.total ?? location.total)
        }
    }

    /// Free and total space asked of the file system each time. URL resource
    /// values are cached by macOS, so after deleting photos they kept
    /// showing the old free space.
    static func freeSpace(at url: URL) -> (available: Int64?, total: Int64?) {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: url.path) else { return (nil, nil) }
        return (
            (attributes[.systemFreeSize] as? NSNumber)?.int64Value,
            (attributes[.systemSize] as? NSNumber)?.int64Value
        )
    }

    /// Folders under `root` that directly contain photos, up to `maxDepth`
    /// levels down. A folder with photos is not searched further, so a
    /// camera card's `DCIM/100MSDCF` is found without reading every file.
    public static func shootFolders(in root: URL, maxDepth: Int = 3) -> [ShootFolder] {
        var results: [ShootFolder] = []
        var budget = folderBudget
        visit(root, root: root, depth: 0, maxDepth: maxDepth, budget: &budget, into: &results)
        return results.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    /// Folders a camera keeps for its own use (clip thumbnails, proxies,
    /// indexes), not files to cull. Sony's clips themselves live in
    /// PRIVATE/M4ROOT/CLIP, which is searched.
    static let skippedFolders: Set<String> = [
        "thmbnl", "sub", "general", "avf_info", "system volume information", "$recycle.bin",
    ]

    /// At most this many folders are read per drive, so a big archive
    /// drive answers in seconds instead of being read end to end.
    static let folderBudget = 400

    private static func visit(
        _ folder: URL, root: URL, depth: Int, maxDepth: Int, budget: inout Int, into results: inout [ShootFolder]
    ) {
        guard budget > 0 else { return }
        budget -= 1
        guard let entries = try? DirectoryListing.entries(of: folder) else { return }
        // A RAW and its camera JPEG are one photo, so each is counted by the
        // name they share rather than by file.
        var photos: Set<String> = []
        var videos: Set<String> = []
        for entry in entries where !entry.isDirectory {
            switch FileKind(extension: entry.fileExtension) {
            case .raw, .image: photos.insert(entry.stem)
            case .video: videos.insert(entry.stem)
            case nil: continue
            }
        }
        videos.subtract(photos)
        if !photos.isEmpty || !videos.isEmpty {
            let path = folder.path.dropFirst(root.path.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            results.append(ShootFolder(url: folder, path: path.isEmpty ? "/" : path, photoCount: photos.count, videoCount: videos.count))
            return
        }
        guard depth < maxDepth else { return }
        for entry in entries where entry.isDirectory {
            // Asking whether a folder is a package needs LaunchServices, so it
            // is asked only of the handful of folders, never of the files.
            guard !skippedFolders.contains(entry.name.lowercased()),
                (try? entry.url.resourceValues(forKeys: [.isPackageKey]))?.isPackage != true
            else { continue }
            visit(entry.url, root: root, depth: depth + 1, maxDepth: maxDepth, budget: &budget, into: &results)
        }
    }
}
