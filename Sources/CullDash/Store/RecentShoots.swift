import Foundation

/// A shoot opened before, for the start screen's "Recent" list.
struct RecentShoot: Codable, Hashable, Identifiable {
    let title: String
    /// One folder, or every photo folder on a drive.
    let folders: [String]
    let root: String
    let opened: Date

    var id: String { root + "|" + folders.joined(separator: "|") }
    var isWholeDrive: Bool { folders.count > 1 || root.hasPrefix("/Volumes/") && folders.first != root }
    /// Gone when the drive is unplugged or the folder was moved.
    var isAvailable: Bool { FileManager.default.fileExists(atPath: root) }
}

/// Remembers the last few shoots in this Mac's user defaults. It is a
/// convenience only: if it can't be read, the list is simply empty.
enum RecentShoots {
    private static let key = "recentShoots"
    static let limit = 6

    static func load() -> [RecentShoot] {
        guard let data = UserDefaults.standard.data(forKey: key),
            let list = try? JSONDecoder().decode([RecentShoot].self, from: data)
        else { return [] }
        return list
    }

    static func remember(title: String, folders: [URL], root: URL) {
        let entry = RecentShoot(title: title, folders: folders.map(\.path), root: root.path, opened: Date())
        var list = load().filter { $0.id != entry.id }
        list.insert(entry, at: 0)
        if let data = try? JSONEncoder().encode(Array(list.prefix(limit))) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
