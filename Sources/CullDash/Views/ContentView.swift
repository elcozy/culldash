import SwiftUI
import CullDashCore

/// The window: the bar on top, then the empty state, the grid or one photo.
struct ContentView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            if store.folder != nil {
                TopBar()
                Rectangle().fill(Theme.hairline).frame(height: 1)
                ToolStrip()
            } else {
                StartBar()
            }
            Rectangle().fill(Theme.hairline).frame(height: 1)
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
        .overlay(alignment: .bottom) { NoticeView().padding(.bottom, 48) }
        .background(Theme.canvas)
        .foregroundStyle(Theme.text)
        .task {
            // `open -a CullDash --args -folder <path>`. A dash argument lands in
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

/// The start screen's top: the window buttons and the name, nothing else.
private struct StartBar: View {
    var body: some View {
        HStack(spacing: 8) {
            LogoMark(size: 22)
            Text("CullDash").font(.system(size: 13, weight: .bold)).tracking(-0.2)
            Text("Cull RAW shoots fast").font(.system(size: 12)).foregroundStyle(Theme.subtle)
            Spacer()
        }
        .padding(.leading, trafficLightInset)
        .frame(height: topBarHeight)
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

/// A short message that floats above the bottom bar for a few seconds.
private struct NoticeView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        if let notice = store.notice {
            Text(notice)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.floatRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.floatRadius).strokeBorder(Theme.hairline))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.2), value: store.notice)
        }
    }
}

/// The keys, always in view, so nobody has to look them up.
private struct HintBar: View {
    private let hints = [
        ("P", "pick"), ("X", "reject"), ("U", "clear"), ("1–5", "stars"), ("6–9", "label"),
        ("Space", "view"), ("Z", "100%"), ("Del", "trash"), ("R", "reject rest"), ("Esc", "back"),
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
