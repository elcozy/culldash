import AppKit
import SwiftUI

@main
struct WinnowApp: App {
    @State private var store = LibraryStore()

    init() {
        // Built outside Xcode, the binary must ask to be a regular app with a
        // Dock icon and a menu bar.
        NSApplication.shared.setActivationPolicy(.regular)
        // macOS can remember "no windows open" from a previous run and then
        // start the app with none. A culling app should always open its window.
        UserDefaults.standard.register(defaults: ["ApplePersistenceIgnoreState": true])
        // Follows the Mac's appearance; `-appearance light` or `dark` pins one.
        switch UserDefaults.standard.string(forKey: "appearance") {
        case "light": NSApplication.shared.appearance = NSAppearance(named: .aqua)
        case "dark": NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        default: break
        }
    }

    var body: some Scene {
        WindowGroup("Winnow") {
            ContentView()
                .environment(store)
                .modifier(KeyCommandsModifier(store: store))
                .frame(minWidth: 960, minHeight: 620)
                .navigationTitle(store.title)
                .background(WindowChrome())
                .ignoresSafeArea(edges: .top)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder…") { store.chooseFolder() }
                    .keyboardShortcut("o")
            }
            CommandGroup(after: .textEditing) {
                Button("Search Photos") { store.searchRequests += 1 }
                    .keyboardShortcut("f")
                    .disabled(store.folder == nil)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo Move to Trash") { Task { await store.undoTrash() } }
                    .keyboardShortcut("z")
                    .disabled(!store.canUndoTrash)
            }
        }
    }
}
