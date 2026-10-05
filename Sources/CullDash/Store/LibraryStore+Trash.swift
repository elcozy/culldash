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

    /// Delete key: the selected photos leave the shoot now and the next one
    /// slides in. The files follow in the background.
    ///
    /// The moving used to be waited for first, which left the deleted photo
    /// still selected while its files were going. Delete is a key people hold
    /// down, so the next press aimed at the same photo, two moves of one file
    /// raced, and the loser reported that it could not be moved.
    func trashSelected() async {
        let targets = selectable()
        guard !targets.isEmpty else { return }
        let position = selectedIndex ?? 0
        extraSelection = []

        take(out: targets)
        let list = visible
        selectedID = list.isEmpty ? nil : list[min(position, list.count - 1)].id
        zoomed = false

        await moveToTrash(targets)
    }

    func trashRejects() async {
        let targets = photos.filter { $0.culling.flag == .reject && !trashing.contains($0.id) }
        guard !targets.isEmpty else { return }
        take(out: targets)
        keepSelectionVisible()
        await moveToTrash(targets)
    }

    /// The selected photos that are not already on their way out.
    private func selectable() -> [Photo] {
        photos.filter { selectedIDs.contains($0.id) && !trashing.contains($0.id) }
    }

    /// Out of the shoot at once, and marked as going, so a second Delete can
    /// neither see them nor aim at their files.
    private func take(out targets: [Photo]) {
        let ids = Set(targets.map(\.id))
        trashing.formUnion(ids)
        photos.removeAll { ids.contains($0.id) }
    }

    /// Moves the files. Anything the file system will not take comes back to
    /// the shoot, rather than being quietly dropped from a list it is still in.
    private func moveToTrash(_ targets: [Photo]) async {
        let ids = Set(targets.map(\.id))
        defer { trashing.subtract(ids) }
        await flushSaves()
        let results = await Task.detached(priority: .userInitiated) {
            targets.map { photo in (photo, try? PhotoTrash.trash(photo)) }
        }.value

        let done = results.compactMap { photo, files in files.map { TrashedPhoto(photo: photo, files: $0) } }
        if !done.isEmpty { trashHistory.append(done) }

        let refused = results.filter { $0.1 == nil }.map(\.0)
        if !refused.isEmpty {
            photos.append(contentsOf: refused)
            photos.sort(by: FolderScanner.captureOrder)
            keepSelectionVisible()
            errorMessage = "\(refused.count) photo\(refused.count == 1 ? "" : "s") couldn't be moved to the Trash."
        } else {
            show(done.count == 1 ? "\(done[0].photo.name) moved to the Trash · ⌘Z to undo"
                : "\(done.count) photos moved to the Trash · ⌘Z to undo")
        }
    }

    /// ⌘Z: puts the last trashed photos back, in their places.
    /// A trimmed copy was written beside the clip it came from. It joins the
    /// shoot straight away, so going back to the grid shows it rather than
    /// leaving it to be found on the card later.
    ///
    /// It takes the original's capture date and its decisions, so it sorts in
    /// right beside its source (the name breaks the tie, and "C0007" comes
    /// before "C0007-trimmed") and arrives already picked or rated the way the
    /// clip it came from was. The selection does not move.
    func noteNewClip(at url: URL, from original: URL) {
        guard !photos.contains(where: { $0.primary == url }),
            let index = photos.firstIndex(where: { $0.primary == original })
        else { return }
        let source = photos[index]
        photos.insert(
            Photo(
                primary: url, kind: .video, modified: source.modified,
                culling: source.culling, camera: source.camera),
            at: index + 1)
        show("\(url.lastPathComponent) added to the shoot")
    }

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
