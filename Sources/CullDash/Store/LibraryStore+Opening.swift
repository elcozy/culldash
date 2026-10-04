import AppKit
import SwiftUI
import CullDashCore

/// Opening a shoot and putting it away: choosing a folder, reading it in
/// the background, and clearing everything the last one left behind.
extension LibraryStore {
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
            adopt(folder: root, title: title)
            photos = found
            filter = PhotoFilter()
            extraSelection = []
            selectedID = found.first?.id
            mode = .grid
            zoomed = false
            trashHistory = []
            groupBursts = false
            showDuplicates = false
            cameras = []
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
        adopt(folder: nil, title: "CullDash")
        photos = []
        selectedID = nil
        mode = .grid
        zoomed = false
        groupBursts = false
        showDuplicates = false
        cameras = []
        cameraProgress = nil
    }
}
