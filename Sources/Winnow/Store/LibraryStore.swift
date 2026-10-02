import AppKit
import SwiftUI
import WinnowCore

/// How the photos are shown.
enum ViewMode {
    case grid
    case loupe
}

/// Holds the open shoot, its photos and the selection, and saves every
/// decision to the photo's XMP sidecar in the background. Trashing and
/// burst grouping live in their own extensions beside this file.
@MainActor @Observable
final class LibraryStore {
    /// The folder or drive the shoot came from; nil on the start screen.
    private(set) var folder: URL?
    /// "winnow-test", or a drive's name when the whole drive is open.
    private(set) var title = "Winnow"
    var photos: [Photo] = []
    var filter = PhotoFilter() { didSet { keepSelectionVisible() } }
    var selectedID: Photo.ID?
    var mode: ViewMode = .grid
    var zoomed = false
    /// Move to the next photo after a flag or rating, so culling is one key per frame.
    var autoAdvance = true
    /// Set by the grid so ↑ and ↓ move a whole row.
    var gridColumns = 1
    var errorMessage: String?
    /// A short message at the bottom of the window, e.g. after a trash.
    var notice: String?
    /// Bumped by ⌘F; the top bar focuses its search field when it changes.
    var searchRequests = 0

    /// Each trash, newest last, so ⌘Z can put photos back.
    var trashHistory: [[TrashedPhoto]] = []
    /// Burst grouping: on/off, the groups found, and progress while finding them.
    var groupBursts = false { didSet { groupBurstsChanged() } }
    var burstOf: [Photo.ID: Int] = [:]
    var burstMembers: [Int: [Photo.ID]] = [:]
    var burstProgress: Double?
    var burstTask: Task<Void, Never>?

    /// Sidecar writes run one after another, so two quick key presses on the
    /// same photo can never land in the wrong order.
    private var lastSave: Task<Void, Never>?
    private var warmTask: Task<Void, Never>?
    private var noticeTask: Task<Void, Never>?

    var visible: [Photo] { photos.filter { filter.matches($0) } }
    var selected: Photo? { photos.first { $0.id == selectedID } }
    var selectedIndex: Int? { visible.firstIndex { $0.id == selectedID } }

    func count(_ flag: FlagFilter) -> Int {
        photos.filter { PhotoFilter(flag: flag, minStars: filter.minStars, kind: filter.kind, search: filter.search).matches($0) }.count
    }

    // MARK: Opening

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
        await open([url], root: url, title: url.lastPathComponent)
    }

    /// Several folders as one shoot, e.g. every photo folder on a card.
    func open(_ folders: [URL], root: URL, title: String) async {
        await flushSaves()
        do {
            let found = try await Task.detached(priority: .userInitiated) { try FolderScanner.scan(folders) }.value
            folder = root
            self.title = title
            photos = found
            filter = PhotoFilter()
            selectedID = found.first?.id
            mode = .grid
            zoomed = false
            trashHistory = []
            groupBursts = false
            warmThumbnails()
            RecentShoots.remember(title: title, folders: folders, root: root)
        } catch {
            errorMessage = "Couldn't open \(title): \(error.localizedDescription)"
        }
    }

    /// Back to the list of drives.
    func closeFolder() async {
        await flushSaves()
        warmTask?.cancel()
        burstTask?.cancel()
        folder = nil
        title = "Winnow"
        photos = []
        selectedID = nil
        mode = .grid
        zoomed = false
        groupBursts = false
    }

    /// Loads every thumbnail in the background, in order, so scrolling the
    /// grid or coming back to it never waits on a spinner.
    private func warmThumbnails() {
        warmTask?.cancel()
        let urls = photos.map(\.primary)
        warmTask = Task.detached(priority: .utility) {
            for url in urls {
                if Task.isCancelled { return }
                _ = PreviewLoader.shared.preview(for: url, maxPixels: PreviewSize.thumbnail)
            }
        }
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

    func update(advance: Bool, _ change: (inout Culling) -> Void) {
        guard let id = selectedID else { return }
        let position = selectedIndex ?? 0
        apply(to: [id], change)
        let list = visible
        if let now = list.firstIndex(where: { $0.id == id }) {
            if autoAdvance && advance { selectedID = list[min(now + 1, list.count - 1)].id }
        } else {
            // It no longer matches the filter; the next photo slides into its place.
            selectedID = list.isEmpty ? nil : list[min(position, list.count - 1)].id
        }
        zoomed = false
    }

    /// Changes several photos at once and saves each one's sidecar.
    func apply(to ids: Set<Photo.ID>, _ change: (inout Culling) -> Void) {
        for index in photos.indices where ids.contains(photos[index].id) {
            change(&photos[index].culling)
            save(photos[index])
        }
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

    func show(_ message: String) {
        notice = message
        noticeTask?.cancel()
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { self?.notice = nil }
        }
    }

    func keepSelectionVisible() {
        let list = visible
        if !list.contains(where: { $0.id == selectedID }) { selectedID = list.first?.id }
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

/// Preview sizes, in pixels on the long edge.
enum PreviewSize {
    static let thumbnail = 400
    /// Larger than any embedded preview, so the camera's full preview is used.
    static let full = 2560
}
