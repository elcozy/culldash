import AppKit
import SwiftUI
import WinnowCore

/// The start screen: the drives plugged in, each opening to the folders on
/// it that hold photos. A small link covers any other folder.
struct EmptyStateView: View {
    @Environment(LibraryStore.self) private var store
    @State private var locations: [StorageLocation] = []
    /// Only one drive is open at a time, so the list never floods.
    @State private var openID: StorageLocation.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choose a shoot")
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.5)
                .padding(.bottom, 4)
            Text("Pick a drive, then a folder. Nothing is imported or copied.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(locations) { location in
                        StorageRow(location: location, isOpen: openID == location.id) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                openID = openID == location.id ? nil : location.id
                            }
                        } onOpen: { folder in
                            Task { await store.open(folder) }
                        }
                    }
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
            }
            .frame(maxHeight: 460)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Button("Choose another folder…") { store.chooseFolder() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                Text("⌘O · or drop a folder here").foregroundStyle(Theme.subtle)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.top, 16)
        }
        .frame(maxWidth: 520)
        .padding(32)
        .onAppear(perform: refresh)
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in refresh() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in refresh() }
    }

    private func refresh() {
        locations = StorageScanner.locations()
        if let openID, !locations.contains(where: { $0.id == openID }) { self.openID = nil }
    }
}

/// One drive: icon, name and space used; open, the photo folders on it.
private struct StorageRow: View {
    let location: StorageLocation
    let isOpen: Bool
    let onToggle: () -> Void
    let onOpen: (URL) -> Void
    @State private var folders: [ShootFolder]?
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: location.kind == .card ? "sdcard.fill" : location.kind == .drive ? "externaldrive.fill" : "photo.on.rectangle")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name).font(.system(size: 14, weight: .semibold))
                        if let usage { Text(usage).font(.system(size: 12)).foregroundStyle(Theme.subtle) }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.subtle)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(hovering ? Theme.raised : .clear, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }

            if isOpen { folderList.padding(.leading, 44).padding(.bottom, 8) }
        }
        .task(id: isOpen) {
            guard isOpen, folders == nil else { return }
            let root = location.url
            folders = await Task.detached(priority: .userInitiated) { StorageScanner.shootFolders(in: root) }.value
        }
    }

    @ViewBuilder private var folderList: some View {
        if let folders {
            if folders.isEmpty {
                Text("No photos found near the top of this drive. Use “Choose another folder…”.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.subtle)
                    .padding(.vertical, 8)
            }
            ForEach(folders) { folder in
                FolderRow(folder: folder) { onOpen(folder.url) }
            }
        } else {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Looking for photos…").font(.system(size: 12)).foregroundStyle(Theme.subtle)
            }
            .padding(.vertical, 8)
        }
    }

    private var usage: String? {
        guard let total = location.total, let available = location.available else { return nil }
        let format = ByteCountFormatter()
        format.countStyle = .file
        return "\(format.string(fromByteCount: available)) free of \(format.string(fromByteCount: total))"
    }
}

/// A folder of photos inside a drive; click to open it.
private struct FolderRow: View {
    let folder: ShootFolder
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "folder").font(.system(size: 12)).foregroundStyle(Theme.subtle)
                Text(folder.path).font(.system(size: 13)).lineLimit(1).truncationMode(.middle)
                Spacer()
                Text("\(folder.photoCount.formatted()) photos").font(.system(size: 12)).foregroundStyle(Theme.subtle)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(hovering ? Theme.accent : .clear)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .background(hovering ? Theme.raised : .clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
