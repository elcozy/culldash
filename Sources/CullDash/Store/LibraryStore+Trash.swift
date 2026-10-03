import Foundation
import CullDashCore

/// A photo that went to the Trash, with its files' way back.
struct TrashedPhoto {
    let photo: Photo
    let files: [TrashedFile]
    /// Set when a clip was replaced by a shorter edit rather than trashed.
    /// The edit now carries the original's name, so undo has to move it out
    /// of the way before the original can come back to that name.
    var replacedBy: URL?

    init(photo: Photo, files: [TrashedFile], replacedBy: URL? = nil) {
        self.photo = photo
        self.files = files
        self.replacedBy = replacedBy
    }
}

/// Trashing photos, one with Delete or all rejects at once, and undoing it.
/// Files always go to the Trash, never straight to deletion.
extension LibraryStore {
    var rejectCount: Int { photos.filter { $0.culling.flag == .reject }.count }
    var canUndoTrash: Bool { !trashHistory.isEmpty }

    /// Delete key: the selected photos go to the Trash now; the next slides in.
    func trashSelected() async {
        let targets = photos.filter { selectedIDs.contains($0.id) }
        guard !targets.isEmpty else { return }
        let position = selectedIndex ?? 0
        extraSelection = []
        await trash(targets)
        let list = visible
        selectedID = list.isEmpty ? nil : list[min(position, list.count - 1)].id
        zoomed = false
    }

    func trashRejects() async {
        await trash(photos.filter { $0.culling.flag == .reject })
        keepSelectionVisible()
    }

    private func trash(_ targets: [Photo]) async {
        guard !targets.isEmpty else { return }
        await flushSaves()
        let results = await Task.detached(priority: .userInitiated) {
            targets.map { photo in (photo, try? PhotoTrash.trash(photo)) }
        }.value
        let done = results.compactMap { photo, files in files.map { TrashedPhoto(photo: photo, files: $0) } }
        let gone = Set(done.map(\.photo.id))
        photos.removeAll { gone.contains($0.id) }
        if !done.isEmpty { trashHistory.append(done) }
        let failed = results.count - done.count
        if failed > 0 {
            errorMessage = "\(failed) photo\(failed == 1 ? "" : "s") couldn't be moved to the Trash."
        } else {
            show(done.count == 1 ? "\(done[0].photo.name) moved to the Trash · ⌘Z to undo"
                : "\(done.count) photos moved to the Trash · ⌘Z to undo")
        }
    }

    /// ⌘Z: puts the last trashed photos back, in their places.
    /// A clip was replaced by a shorter edit and the original went to the
    /// Trash. It joins the undo history, so Cmd-Z puts the long one back just
    /// as it would a rejected frame.
    func noteReplacedClip(_ trashed: TrashedFile) {
        guard let photo = photos.first(where: { $0.primary == trashed.original }) else { return }
        trashHistory.append([TrashedPhoto(photo: photo, files: [trashed], replacedBy: trashed.original)])
        show("\(trashed.original.lastPathComponent) replaced · ⌘Z to undo")
    }

    func undoTrash() async {
        guard let last = trashHistory.popLast() else { return }
        let restored = await Task.detached(priority: .userInitiated) {
            last.filter { entry in
                // A replaced clip: the edit has to go to the Trash first, or
                // there is already a file sitting under the name the original
                // wants back and the move fails.
                if let edit = entry.replacedBy, (try? PhotoTrash.trash(edit)) == nil { return false }
                return (try? PhotoTrash.restore(entry.files)) != nil
            }
        }.value
        // A replaced clip never left the shoot, so only the trashed ones are
        // added back; adding the others would list them twice.
        let returning = restored.filter { $0.replacedBy == nil }.map(\.photo)
        photos.append(contentsOf: returning)
        photos.sort(by: FolderScanner.captureOrder)
        selectedID = returning.first?.id ?? selectedID
        if restored.contains(where: { $0.replacedBy != nil }) {
            show(restored.count == 1 ? "\(restored[0].photo.name) is back to its full length"
                : "\(restored.count) clips are back")
        } else {
            show(returning.count == 1 ? "\(returning[0].name) is back" : "\(returning.count) photos are back")
        }
    }
}
