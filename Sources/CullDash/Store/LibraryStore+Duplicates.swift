import Foundation
import CullDashCore

/// Exact duplicates: finding the photos whose files are byte for byte the
/// same, and keeping one of each.
extension LibraryStore {
    /// Copies beyond the first of each group — the number that can go.
    var extraCopyCount: Int { duplicateGroups.reduce(0) { $0 + $1.count - 1 } }

    /// Which duplicate group a photo is in, when it is in one.
    func duplicates(of id: Photo.ID) -> [Photo.ID]? {
        guard let group = duplicateOf[id], duplicateGroups.indices.contains(group) else { return nil }
        return duplicateGroups[group]
    }

    func showDuplicatesChanged() {
        duplicateTask?.cancel()
        guard showDuplicates else {
            duplicateOf = [:]
            duplicateGroups = []
            duplicateProgress = nil
            return
        }
        let shoot = photos
        duplicateProgress = 0
        duplicateTask = Task { [weak self] in
            let groups = await Task.detached(priority: .userInitiated) {
                DuplicateFinder.groups(in: shoot) { fraction in
                    Task { @MainActor in self?.duplicateProgress = fraction }
                } isCancelled: {
                    Task.isCancelled
                }
            }.value
            guard let self, !Task.isCancelled, self.showDuplicates else { return }
            self.duplicateGroups = groups
            self.duplicateOf = Dictionary(
                uniqueKeysWithValues: groups.enumerated().flatMap { index, group in
                    group.map { ($0, index) }
                })
            self.duplicateProgress = nil
            self.keepSelectionVisible()
            self.show(
                groups.isEmpty
                    ? "No exact duplicates in this shoot"
                    : "\(groups.count) set\(groups.count == 1 ? "" : "s") of duplicates · \(self.extraCopyCount) extra cop\(self.extraCopyCount == 1 ? "y" : "ies")")
        }
    }

    /// Rejects every copy but one in each set, so the Trash button takes them
    /// all in one go and ⌘Z brings them back.
    ///
    /// A copy that has been picked is kept, and keeps its fellows company: if
    /// nothing in a set is picked, the first is the one that stays. Rejecting
    /// rather than deleting means the count is visible and the decision is
    /// still reversible right up to the moment the Trash button is pressed.
    func keepOneOfEach() {
        guard !duplicateGroups.isEmpty else { return }
        var doomed: Set<Photo.ID> = []
        for group in duplicateGroups {
            let picked = group.filter { photo(group: $0)?.culling.flag == .pick }
            let keepers = picked.isEmpty ? Array(group.prefix(1)) : picked
            doomed.formUnion(Set(group).subtracting(keepers))
        }
        guard !doomed.isEmpty else { return }
        apply(to: doomed) { $0.flag = .reject }
        keepSelectionVisible()
        show("\(doomed.count) extra cop\(doomed.count == 1 ? "y" : "ies") rejected · Trash them, ⌘Z undoes")
    }

    private func photo(group id: Photo.ID) -> Photo? { photos.first { $0.id == id } }
}
