import AppKit

/// An app on this Mac that can open the photos, offered under "Send to".
struct Editor: Identifiable, Hashable {
    let url: URL
    let name: String
    var id: URL { url }
}

/// Finds the apps that open a kind of photo and hands photos to one.
///
/// Opening files "with" Lightroom is the same as dropping them on its icon:
/// it starts an import of exactly those files. Lightroom reads stars and
/// labels from the XMP sidecars on import.
enum EditorLauncher {
    /// Editors photographers send to most, in the order they are listed.
    static let preferred = ["Lightroom Classic", "Lightroom", "Capture One", "Photoshop", "darktable", "X RAW STUDIO"]

    static func editors(for sample: URL) -> [Editor] {
        var seen = Set<String>()
        return NSWorkspace.shared.urlsForApplications(toOpen: sample)
            .map { Editor(url: $0, name: FileManager.default.displayName(atPath: $0.path).replacingOccurrences(of: ".app", with: "")) }
            .filter { seen.insert($0.name).inserted }
            .sorted { rank($0) == rank($1) ? $0.name < $1.name : rank($0) < rank($1) }
    }

    static func open(_ files: [URL], in editor: Editor) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        _ = try await NSWorkspace.shared.open(files, withApplicationAt: editor.url, configuration: configuration)
    }

    private static func rank(_ editor: Editor) -> Int {
        preferred.firstIndex { editor.name.localizedCaseInsensitiveContains($0) } ?? preferred.count
    }
}
