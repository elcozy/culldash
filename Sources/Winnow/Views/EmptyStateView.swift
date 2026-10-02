import SwiftUI

/// What the window shows before a folder is open.
struct EmptyStateView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent)
            Text("Open a shoot")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)
            Text("Choose a folder of RAW or JPEG files, on this Mac or an external drive, or drop it here. Nothing is imported or copied.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Button {
                store.chooseFolder()
            } label: {
                Label("Open folder", systemImage: "folder")
            }
            .buttonStyle(ToneButtonStyle(.primary))
            .keyboardShortcut("o")
            Text("⌘O").font(.system(size: 11)).foregroundStyle(Theme.subtle)
        }
        .padding(32)
    }
}
