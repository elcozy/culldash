import Foundation
import WinnowCore

/// Grouping near-identical frames (bursts and re-takes of one pose) so one
/// or two can be kept and the rest rejected in one go.
extension LibraryStore {
    /// The burst the photo belongs to, when it has company.
    func burst(of id: Photo.ID) -> [Photo.ID]? {
        guard let group = burstOf[id], let members = burstMembers[group], members.count > 1 else { return nil }
        return members
    }

    var burstCount: Int { burstMembers.values.filter { $0.count > 1 }.count }

    func groupBurstsChanged() {
        burstTask?.cancel()
        guard groupBursts else {
            burstOf = [:]
            burstMembers = [:]
            burstProgress = nil
            return
        }
        let shoot = photos
        burstProgress = 0
        burstTask = Task { [weak self] in
            let groups = await Task.detached(priority: .userInitiated) {
                SimilarityPrints.bursts(in: shoot) { fraction in
                    Task { @MainActor in self?.burstProgress = fraction }
                }
            }.value
            guard let self, !Task.isCancelled, self.groupBursts else { return }
            var of: [Photo.ID: Int] = [:]
            var members: [Int: [Photo.ID]] = [:]
            for (index, group) in groups.enumerated() {
                members[index] = group
                for id in group { of[id] = index }
            }
            self.burstOf = of
            self.burstMembers = members
            self.burstProgress = nil
            self.show("\(self.burstCount) groups of similar shots found")
        }
    }

    /// R: rejects every photo in the selected photo's burst that isn't a pick.
    func rejectRestOfBurst() {
        guard let id = selectedID, let members = burst(of: id) else { return }
        rejectRest(of: members)
    }

    func rejectRest(of members: [Photo.ID]) {
        let picked = Set(photos.filter { members.contains($0.id) && $0.culling.flag == .pick }.map(\.id))
        guard !picked.isEmpty else {
            show("Pick the keepers with P first, then reject the rest")
            return
        }
        apply(to: Set(members).subtracting(picked)) { $0.flag = .reject }
        keepSelectionVisible()
        show("Kept \(picked.count), rejected \(members.count - picked.count)")
    }
}
