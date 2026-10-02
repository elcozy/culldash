import AppKit
import SwiftUI

@main
struct WinnowApp: App {
    @State private var store = LibraryStore()

    init() {
        // Built outside Xcode, the binary must ask to be a regular app with a
        // Dock icon and a menu bar.
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("Winnow") {
            ContentView()
                .environment(store)
                .modifier(KeyCommandsModifier(store: store))
                .preferredColorScheme(.dark)
                .frame(minWidth: 960, minHeight: 620)
                .navigationTitle(store.title)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder…") { store.chooseFolder() }
                    .keyboardShortcut("o")
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo Move to Trash") { Task { await store.undoTrash() } }
                    .keyboardShortcut("z")
                    .disabled(!store.canUndoTrash)
            }
        }
    }
}
