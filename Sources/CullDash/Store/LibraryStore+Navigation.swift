import CullDashCore
import Foundation

/// Moving through the shoot: arrows, rows, grid and full screen, zoom, back.
extension LibraryStore {
    func move(by offset: Int) {
        extraSelection = []
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
}
