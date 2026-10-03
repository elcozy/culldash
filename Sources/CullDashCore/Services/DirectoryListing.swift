import Foundation

/// One item in a folder: its name, whether it is itself a folder, and when it
/// was last written.
public struct DirectoryEntry: Sendable {
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let modified: Date
    /// `arw` for `DSC01850.ARW`, lowercased.
    public let fileExtension: String
    /// `dsc01850` for `DSC01850.ARW`: the part a RAW, its camera JPEG and its
    /// XMP sidecar share, which is how they find each other.
    public let stem: String

    init(folder: URL, name: String, isDirectory: Bool, modified: Date) {
        self.url = folder.appendingPathComponent(name, isDirectory: isDirectory)
        self.name = name
        self.isDirectory = isDirectory
        self.modified = modified
        // Split on the last dot by hand: building a URL per file to ask it the
        // same question costs more than the directory read itself.
        if let dot = name.lastIndex(of: "."), dot != name.startIndex {
            fileExtension = String(name[name.index(after: dot)...]).lowercased()
            stem = String(name[..<dot]).lowercased()
        } else {
            fileExtension = ""
            stem = name.lowercased()
        }
    }
}

/// Lists a folder in bulk, names and attributes together.
///
/// `FileManager.contentsOfDirectory` fetches attributes one item at a time,
/// which on an external drive is a seek per file. Listing a 3,858-file card
/// folder on a USB hard drive that way took 39 seconds from cold; the same
/// folder through `getattrlistbulk` takes about 100 ms, modification dates
/// included. That difference is the whole of the wait before a drive's folders
/// appear, so every scan goes through here.
public enum DirectoryListing {
    /// The visible items in `folder`. Hidden files are left out, which on a
    /// camera card also drops the `._DSC01850.ARW` companions macOS writes
    /// beside every file on exFAT — half the entries on a card, and none of
    /// them photos.
    public static func entries(of folder: URL) throws -> [DirectoryEntry] {
        let descriptor = open(folder.path, O_RDONLY | O_DIRECTORY, 0)
        guard descriptor >= 0 else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSURLErrorKey: folder])
        }
        defer { close(descriptor) }
        guard let bulk = try bulkEntries(descriptor, folder: folder) else {
            // A volume that has no bulk call (some network shares): the slow
            // path is still better than no photos.
            return try fallbackEntries(folder)
        }
        return bulk
    }

    /// The attributes asked for, in the order `getattrlistbulk` returns them,
    /// which is the order they are declared in `<sys/attr.h>`.
    private static var requestedAttributes: attrlist {
        var list = attrlist()
        list.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        list.commonattr =
            attrgroup_t(ATTR_CMN_RETURNED_ATTRS) | attrgroup_t(ATTR_CMN_NAME)
            | attrgroup_t(ATTR_CMN_OBJTYPE) | attrgroup_t(ATTR_CMN_MODTIME)
            | attrgroup_t(ATTR_CMN_FLAGS)
        return list
    }

    /// `nil` when the file system has no bulk call, so the caller falls back.
    private static func bulkEntries(_ descriptor: Int32, folder: URL) throws -> [DirectoryEntry]? {
        var attributes = requestedAttributes
        var entries: [DirectoryEntry] = []
        // 256 KB holds a few thousand entries, so a card folder is two or
        // three calls rather than one per file.
        var buffer = [UInt8](repeating: 0, count: 256 * 1024)

        while true {
            let count = buffer.withUnsafeMutableBytes { raw in
                Int(getattrlistbulk(descriptor, &attributes, raw.baseAddress, raw.count, 0))
            }
            if count == 0 { break }
            if count < 0 {
                if errno == ENOTSUP { return nil }
                throw CocoaError(.fileReadUnknown, userInfo: [NSURLErrorKey: folder])
            }
            buffer.withUnsafeBytes { raw in
                var cursor = raw.baseAddress!
                for _ in 0..<count {
                    let start = cursor
                    let length = Int(cursor.loadUnaligned(as: UInt32.self))
                    if let entry = parse(cursor, folder: folder) { entries.append(entry) }
                    cursor = start + length
                }
            }
        }
        return entries
    }

    /// Reads one entry out of the bulk buffer. Each attribute follows the last
    /// one, so they are read in declaration order and skipped when absent.
    private static func parse(_ record: UnsafeRawPointer, folder: URL) -> DirectoryEntry? {
        var field = record + MemoryLayout<UInt32>.size
        let returned = field.loadUnaligned(as: attribute_set_t.self)
        field += MemoryLayout<attribute_set_t>.size

        func has(_ attribute: Int32) -> Bool {
            returned.commonattr & attrgroup_t(attribute) != 0
        }

        guard has(ATTR_CMN_NAME) else { return nil }
        let reference = field.loadUnaligned(as: attrreference_t.self)
        let name = String(
            cString: (field + Int(reference.attr_dataoffset)).assumingMemoryBound(to: CChar.self))
        field += MemoryLayout<attrreference_t>.size

        var isDirectory = false
        if has(ATTR_CMN_OBJTYPE) {
            isDirectory = field.loadUnaligned(as: fsobj_type_t.self) == fsobj_type_t(VDIR.rawValue)
            field += MemoryLayout<fsobj_type_t>.size
        }
        var modified = Date.distantPast
        if has(ATTR_CMN_MODTIME) {
            let stamp = field.loadUnaligned(as: timespec.self)
            modified = Date(timeIntervalSince1970: Double(stamp.tv_sec) + Double(stamp.tv_nsec) / 1e9)
            field += MemoryLayout<timespec>.size
        }
        var hidden = false
        if has(ATTR_CMN_FLAGS) {
            hidden = field.loadUnaligned(as: UInt32.self) & UInt32(UF_HIDDEN) != 0
            field += MemoryLayout<UInt32>.size
        }

        guard !hidden, !name.hasPrefix("."), name != "..", !name.isEmpty else { return nil }
        return DirectoryEntry(folder: folder, name: name, isDirectory: isDirectory, modified: modified)
    }

    /// For file systems without `getattrlistbulk`.
    private static func fallbackEntries(_ folder: URL) throws -> [DirectoryEntry] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])
        return urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return DirectoryEntry(
                folder: folder,
                name: url.lastPathComponent,
                isDirectory: values?.isDirectory == true,
                modified: values?.contentModificationDate ?? .distantPast
            )
        }
    }
}
