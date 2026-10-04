import AppKit
import SwiftUI
import CullDashCore

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
    /// "culldash-test", or a drive's name when the whole drive is open.
    private(set) var title = "CullDash"
    var photos: [Photo] = []
    var filter = PhotoFilter() { didSet { keepSelectionVisible() } }
    /// The photo in focus: shown full screen, moved by the arrow keys.
    var selectedID: Photo.ID?
    /// Extra photos picked with ⇧- or ⌘-click; decisions apply to all of them.
    var extraSelection: Set<Photo.ID> = []
    /// The details column on the right.
    var showInspector = false
    var mode: ViewMode = .grid
    var zoomed = false
    /// Move to the next photo after a flag or rating, so culling is one key per frame.
    var autoAdvance = true
    /// Set by the grid so ↑ and ↓ move a whole row.
    var gridColumns = 1
    var errorMessage: String?
    /// A short message at the bottom of the window, e.g. after a trash.
    var notice: String?
    /// Bumped by Space on a clip; the clip editor plays or pauses when it
    /// changes. The player itself lives in the view, so this is how a key
    /// press reaches it.
    var clipPlaybackToggles = 0
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

    /// Exact duplicates: whether the shoot is narrowed to them, the groups
    /// found, and progress while looking.
    var showDuplicates = false { didSet { showDuplicatesChanged() } }
    var duplicateOf: [Photo.ID: Int] = [:]
    var duplicateGroups: [[Photo.ID]] = []
    var duplicateProgress: Double?
    var duplicateTask: Task<Void, Never>?

    /// The cameras the shoot was shot on, in name order, filled in by the
    /// background pass as it reads each photo. The Filters menu lists these.
    var cameras: [String] = []
    /// How far that pass has got, 0 to 1, or nil once every photo is read.
    var cameraProgress: Double?
    var warmTask: Task<Void, Never>?

    /// Sidecar writes run one after another, so two quick key presses on the
    /// same photo can never land in the wrong order.
    private var lastSave: Task<Void, Never>?
    private var noticeTask: Task<Void, Never>?

    var visible: [Photo] {
        let shown = photos.filter { filter.matches($0) }
        // Looking for duplicates narrows the shoot to them, so the extras can
        // be dealt with without the rest of the shoot in the way.
        guard showDuplicates else { return shown }
        return shown.filter { duplicateOf[$0.id] != nil }
    }

    /// Every selected photo: the focused one plus any ⇧/⌘-clicked ones.
    var selectedIDs: Set<Photo.ID> {
        guard let selectedID else { return extraSelection }
        return extraSelection.union([selectedID])
    }
    var selected: Photo? { photos.first { $0.id == selectedID } }

    /// What sharing hands over: every selected photo and all of its files, so
    /// a RAW's camera JPEG goes with it rather than being left behind.
    var shareTargets: [URL] {
        photos.filter { selectedIDs.contains($0.id) }.flatMap(\.allFiles)
    }
    var selectedIndex: Int? { visible.firstIndex { $0.id == selectedID } }

    /// Only opening or closing a shoot changes these two, which is why their
    /// setters stay shut to everything else and this is the one way in.
    func adopt(folder: URL?, title: String) {
        self.folder = folder
        self.title = title
    }

    func count(_ flag: FlagFilter) -> Int {
        var counting = filter
        counting.flag = flag
        return photos.filter { counting.matches($0) }.count
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
        // Several selected: change them all and stay put.
        if extraSelection.count > 0 {
            apply(to: selectedIDs, change)
            show("Changed \(selectedIDs.count) photos")
            return
        }
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
