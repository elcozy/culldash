import AppKit
import SwiftUI
import WinnowCore

/// How the photos are shown.
enum ViewMode {
    case grid
    case loupe
}

/// Holds the open folder, its photos and the selection, and saves every
/// decision to the photo's XMP sidecar in the background.
@MainActor @Observable
final class LibraryStore {
    private(set) var folder: URL?
    private(set) var photos: [Photo] = []
    var filter = PhotoFilter() { didSet { keepSelectionVisible() } }
    var selectedID: Photo.ID?
    var mode: ViewMode = .grid
    var zoomed = false
    /// Move to the next photo after a flag or rating, so culling is one key per frame.
    var autoAdvance = true
    /// Set by the grid so ↑ and ↓ move a whole row.
    var gridColumns = 1
    var errorMessage: String?

    /// Sidecar writes run one after another, so two quick key presses on the
    /// same photo can never land in the wrong order.
    private var lastSave: Task<Void, Never>?

    var visible: [Photo] { photos.filter { filter.matches($0) } }
    var selected: Photo? { photos.first { $0.id == selectedID } }
    var selectedIndex: Int? { visible.firstIndex { $0.id == selectedID } }

    func count(_ flag: FlagFilter) -> Int {
        photos.filter { PhotoFilter(flag: flag, minStars: filter.minStars, kind: filter.kind).matches($0) }.count
    }

    // MARK: Folder

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Open"
        panel.message = "Choose a folder of photos. Nothing is imported or copied."
        if panel.runModal() == .OK, let url = panel.url {
            Task { await open(url) }
        }
    }

    func open(_ url: URL) async {
        await flushSaves()
        do {
            let found = try await Task.detached(priority: .userInitiated) { try FolderScanner.scan(url) }.value
            folder = url
            photos = found
            filter = PhotoFilter()
            selectedID = found.first?.id
            mode = .grid
            zoomed = false
        } catch {
            errorMessage = "Couldn't open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    /// Back to the list of drives.
    func closeFolder() async {
        await flushSaves()
        folder = nil
        photos = []
        selectedID = nil
        mode = .grid
        zoomed = false
    }

    // MARK: Moving around

    func move(by offset: Int) {
        let list = visible
        guard !list.isEmpty else { return }
        let index = selectedIndex ?? 0
        selectedID = list[min(max(index + offset, 0), list.count - 1)].id
        zoomed = false
    }

    func moveRow(_ direction: Int) {
        move(by: mode == .grid ? direction * gridColumns : direction)
    }

    func toggleMode() {
        mode = mode == .grid ? .loupe : .grid
        zoomed = false
    }

    func toggleZoom() {
        if mode == .grid { mode = .loupe }
        zoomed.toggle()
    }

    func back() {
        if zoomed { zoomed = false } else { mode = .grid }
    }

    // MARK: Decisions

    func setFlag(_ flag: Flag) { update(advance: true) { $0.flag = flag } }

    func setRating(_ rating: Int) {
        update(advance: true) { culling in
            culling.rating = rating
            if rating > 0 && culling.flag == .reject { culling.flag = .none }
        }
    }

    /// Labels toggle and don't advance, as in Lightroom.
    func setLabel(_ label: ColorLabel) {
        update(advance: false) { $0.label = $0.label == label ? .none : label }
    }

    private func update(advance: Bool, _ change: (inout Culling) -> Void) {
        guard let id = selectedID, let index = photos.firstIndex(where: { $0.id == id }) else { return }
        let position = selectedIndex ?? 0
        change(&photos[index].culling)
        save(photos[index])
        let list = visible
        if let now = list.firstIndex(where: { $0.id == id }) {
            if autoAdvance && advance { selectedID = list[min(now + 1, list.count - 1)].id }
        } else {
            // It no longer matches the filter; the next photo slides into its place.
            selectedID = list.isEmpty ? nil : list[min(position, list.count - 1)].id
        }
        zoomed = false
    }

    private func save(_ photo: Photo) {
        let previous = lastSave
        let culling = photo.culling
        let sidecar = photo.sidecar
        lastSave = Task.detached(priority: .utility) { [weak self] in
            await previous?.value
            do {
                try XMPSidecar.write(culling, to: sidecar)
            } catch {
                await self?.report("Couldn't save \(sidecar.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    func flushSaves() async { await lastSave?.value }

    private func report(_ message: String) { errorMessage = message }

    private func keepSelectionVisible() {
        let list = visible
        if !list.contains(where: { $0.id == selectedID }) { selectedID = list.first?.id }
    }

    // MARK: Hand-offs

    var rejectCount: Int { photos.filter { $0.culling.flag == .reject }.count }

    /// Moves every reject's files to the Trash; anything that fails stays listed.
    func trashRejects() async {
        await flushSaves()
        let rejects = photos.filter { $0.culling.flag == .reject }
        let failed = await Task.detached(priority: .userInitiated) {
            rejects.filter { (try? PhotoTrash.trash($0)) == nil }.map(\.id)
        }.value
        let kept = Set(failed)
        photos.removeAll { $0.culling.flag == .reject && !kept.contains($0.id) }
        keepSelectionVisible()
        if !failed.isEmpty { errorMessage = "\(failed.count) rejects couldn't be moved to the Trash." }
    }

    /// Opens the photos shown in another app, after their sidecars are written
    /// so the app reads the latest stars and labels.
    func send(to editor: Editor) async {
        await flushSaves()
        do {
            try await EditorLauncher.open(visible.map(\.primary), in: editor)
        } catch {
            errorMessage = "Couldn't open the photos in \(editor.name): \(error.localizedDescription)"
        }
    }
}
