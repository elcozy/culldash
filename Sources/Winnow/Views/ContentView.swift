import SwiftUI
import WinnowCore

/// The window: the bar on top, then the empty state, the grid or one photo.
struct ContentView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            if store.folder != nil {
                TopBar()
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
            Group {
                if store.folder == nil {
                    EmptyStateView()
                } else if store.visible.isEmpty {
                    NoMatchesView()
                } else if store.mode == .grid {
                    PhotoGrid()
                } else {
                    LoupeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if store.folder != nil {
                Rectangle().fill(Theme.hairline).frame(height: 1)
                HintBar()
            }
        }
        .background(Theme.canvas)
        .foregroundStyle(Theme.text)
        .task {
            // `open -a Winnow --args -folder <path>`. A dash argument lands in
            // UserDefaults; a bare path would make AppKit treat it as a file
            // to open and skip the main window.
            if store.folder == nil, let path = UserDefaults.standard.string(forKey: "folder") {
                await store.open(URL(fileURLWithPath: path, isDirectory: true))
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let folder = urls.first(where: \.hasDirectoryPath) else { return false }
            Task { await store.open(folder) }
            return true
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

/// Shown when the filter hides every photo.
private struct NoMatchesView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 32)).foregroundStyle(Theme.subtle)
            Text("No photos match this filter").font(.system(size: 15, weight: .semibold))
            Button("Show all") { store.filter = PhotoFilter() }.buttonStyle(ToneButtonStyle(.secondary))
        }
    }
}

/// The keys, always in view, so nobody has to look them up.
private struct HintBar: View {
    private let hints = [
        ("P", "pick"), ("X", "reject"), ("U", "clear"), ("1–5", "stars"), ("6–9", "label"),
        ("Space", "view"), ("Z", "100%"), ("Esc", "back"),
    ]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(hints, id: \.0) { key, action in
                HStack(spacing: 5) {
                    Text(key)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 4))
                    Text(action).font(.system(size: 11)).foregroundStyle(Theme.subtle)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
    }
}
