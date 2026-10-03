import AppKit
import SwiftUI
import CullDashCore

/// The start screen. Left: a welcome, recent shoots and the main keys.
/// Right: the drives plugged in, each opening to its photo folders.
struct EmptyStateView: View {
    @Environment(LibraryStore.self) private var store
    @State private var locations: [StorageLocation] = []
    @State private var recents: [RecentShoot] = []
    /// Only one drive is open at a time, so the list never floods.
    @State private var openID: StorageLocation.ID?
    @State private var spin = 0.0
    /// Changed by the refresh button, so every drive row starts over and
    /// counts its folders again.
    @State private var generation = 0

    var body: some View {
        HStack(alignment: .top, spacing: 56) {
            welcome.frame(width: 300, alignment: .leading)
            storage.frame(maxWidth: 560)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: refresh)
        // Free space changes as photos are trashed or copied; keep it current.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                locations = StorageScanner.locations()
            }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in refresh() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in refresh() }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Theme.accent)
                .padding(.bottom, 18)
            Text("Choose a shoot")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.8)
            Text("Pick a card, a drive or a folder on this Mac. Photos and videos stay where they are: nothing is imported or copied.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            if !recents.isEmpty {
                SectionTitle("Recent").padding(.top, 32)
                ForEach(recents) { recent in
                    RecentRow(recent: recent) {
                        Task {
                            await store.open(
                                recent.folders.map { URL(fileURLWithPath: $0, isDirectory: true) },
                                root: URL(fileURLWithPath: recent.root, isDirectory: true),
                                title: recent.title)
                        }
                    }
                }
            }

            SectionTitle("Keys").padding(.top, 32)
            VStack(alignment: .leading, spacing: 8) {
                KeyTip(key: "P", text: "pick a keeper")
                KeyTip(key: "X", text: "reject")
                KeyTip(key: "1–5", text: "stars")
                KeyTip(key: "Del", text: "to the Trash, ⌘Z undoes")
            }
        }
    }

    private var storage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle("Storage")
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) { spin += 360 }
                    generation += 1
                    refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(spin))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.muted)
                .help("Look for drives and cards again")
            }
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(locations) { location in
                        StorageRow(location: location, isOpen: openID == location.id, generation: generation) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                openID = openID == location.id ? nil : location.id
                            }
                        } onOpen: { folders, title in
                            Task { await store.open(folders, root: location.url, title: title) }
                        }
                    }
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
            }

            HStack(spacing: 6) {
                Button("Choose a folder…") { store.chooseFolder() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                Text("⌘O · or drop a folder anywhere").foregroundStyle(Theme.subtle)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.top, 14)
        }
    }

    private func refresh() {
        locations = StorageScanner.locations()
        recents = RecentShoots.load()
        if let openID, !locations.contains(where: { $0.id == openID }) { self.openID = nil }
    }
}

/// A small plain-text label above a group (never a pill).
private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.subtle)
            .padding(.bottom, 8)
    }
}

private struct RecentRow: View {
    let recent: RecentShoot
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: recent.isWholeDrive ? "externaldrive" : "folder")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.subtle)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(recent.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                    Text(recent.opened.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.subtle)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .background(hovering ? Theme.raised : .clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!recent.isAvailable)
        .opacity(recent.isAvailable ? 1 : 0.4)
        .help(recent.isAvailable ? recent.root : "Plug in the drive to open this again")
        .onHover { hovering = $0 }
    }
}

private struct KeyTip: View {
    let key: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(minWidth: 34)
                .padding(.vertical, 3)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 5))
            Text(text).font(.system(size: 12)).foregroundStyle(Theme.muted)
        }
    }
}
