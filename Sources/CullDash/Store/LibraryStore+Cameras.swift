import CullDashCore
import Foundation

/// The one background pass over a shoot: it loads every thumbnail and, while
/// each file is open, notes which camera took it.
///
/// They are one pass on purpose. Reading the camera means opening the photo,
/// and on a card or a USB drive that is a seek per file — a second pass of its
/// own over a 8,000-photo drive took over two minutes. Riding along with the
/// thumbnail read costs almost nothing, because the file is already in the
/// page cache by the time the camera is asked for.
extension LibraryStore {
    /// Loads every thumbnail in order, so scrolling the grid or coming back to
    /// it never waits on a spinner, and collects the cameras as it goes.
    func warmThumbnails() {
        warmTask?.cancel()
        let photos = self.photos
        cameraProgress = photos.isEmpty ? nil : 0
        warmTask = Task.detached(priority: .utility) { [weak self] in
            // Reported in batches: a shoot is thousands of photos, and the
            // filter menu does not need to be rebuilt for each one.
            var batch: [(Photo.ID, String)] = []
            for (index, photo) in photos.enumerated() {
                if Task.isCancelled { return }
                _ = PreviewLoader.shared.preview(for: photo.primary, maxPixels: PreviewSize.thumbnail)
                if let camera = ExposureInfo.cameraModel(photo.primary) {
                    batch.append((photo.id, camera))
                }
                let isLast = index == photos.count - 1
                if batch.count >= 50 || isLast {
                    let found = batch
                    batch = []
                    let progress = isLast ? nil : Double(index + 1) / Double(photos.count)
                    await self?.absorb(found, progress: progress)
                }
            }
            await self?.finishCameraPass()
        }
    }

    /// Hands a batch of cameras back to the shoot on the main actor.
    func absorb(_ found: [(Photo.ID, String)], progress: Double?) {
        cameraProgress = progress
        guard !found.isEmpty else { return }
        let byID = Dictionary(found, uniquingKeysWith: { first, _ in first })
        for index in photos.indices {
            if let camera = byID[photos[index].id] { photos[index].camera = camera }
        }
        let names = Set(cameras).union(found.map(\.1))
        cameras = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func finishCameraPass() {
        cameraProgress = nil
    }

    /// A camera filter can only be trusted once every photo has been read, so
    /// the menu says so while the pass is still running.
    var isReadingCameras: Bool { cameraProgress != nil }
}
