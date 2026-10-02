import AppKit
import CullDashCore

/// Clicking in the grid: a plain click selects one photo, ⌘-click adds or
/// removes one, ⇧-click selects the range from the focused photo.
extension LibraryStore {
    func click(_ id: Photo.ID) {
        let modifiers = NSEvent.modifierFlags
        if modifiers.contains(.command) {
            if selectedIDs.contains(id) && selectedIDs.count > 1 {
                extraSelection.remove(id)
                if selectedID == id { selectedID = extraSelection.first }
                extraSelection.remove(selectedID ?? id)
            } else {
                if let current = selectedID { extraSelection.insert(current) }
                selectedID = id
            }
        } else if modifiers.contains(.shift), let anchor = selectedID {
            let list = visible.map(\.id)
            if let from = list.firstIndex(of: anchor), let to = list.firstIndex(of: id) {
                extraSelection.formUnion(list[min(from, to)...max(from, to)])
                selectedID = id
            }
        } else {
            extraSelection = []
            selectedID = id
        }
    }

    func selectAll() {
        extraSelection = Set(visible.map(\.id))
        if selectedID == nil { selectedID = visible.first?.id }
    }

    func clearSelection() { extraSelection = [] }
}
