import Foundation
import CullDashCore

/// A photo that went to the Trash, with its files' way back.
struct TrashedPhoto {
    let photo: Photo
    let files: [TrashedFile]
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
    func undoTrash() async {
        guard let last = trashHistory.popLast() else { return }
        let restored = await Task.detached(priority: .userInitiated) {
            last.filter { (try? PhotoTrash.restore($0.files)) != nil }.map(\.photo)
        }.value
        photos.append(contentsOf: restored)
        photos.sort(by: FolderScanner.captureOrder)
        selectedID = restored.first?.id ?? selectedID
        show(restored.count == 1 ? "\(restored[0].name) is back" : "\(restored.count) photos are back")
    }
}
