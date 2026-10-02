import SwiftUI
import CullDashCore

/// One drive on the start screen: icon, name, kind and a capacity bar,
/// "Open all" for every photo on it, and, opened, its photo folders.
struct StorageRow: View {
    let location: StorageLocation
    let isOpen: Bool
    let onToggle: () -> Void
    /// The folders to open as one shoot, and the shoot's title.
    let onOpen: ([URL], String) -> Void
    @State private var folders: [ShootFolder]?
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onToggle) { header }
                    .buttonStyle(.plain)
                if location.kind != .mac {
                    Button("Open all") { Task { await openAll() } }
                        .buttonStyle(ToneButtonStyle(.secondary))
                        .help("Every photo on \(location.name), from all its folders, as one shoot")
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(hovering ? Theme.raised.opacity(0.6) : .clear, in: RoundedRectangle(cornerRadius: Theme.floatRadius))
            .onHover { hovering = $0 }

            if isOpen { folderList.padding(.leading, 58).padding(.trailing, 10).padding(.bottom, 10) }
        }
        .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 1) }
        .task(id: isOpen) {
            if isOpen { await loadFolders() }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Theme.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(location.name).font(.system(size: 15, weight: .semibold))
                    Text(kindName).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.subtle)
                }
                if let used = usedFraction {
                    CapacityBar(fraction: used).frame(width: 180, height: 4)
                }
                if let usage { Text(usage).font(.system(size: 12)).foregroundStyle(Theme.subtle) }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.subtle)
                .rotationEffect(.degrees(isOpen ? 90 : 0))
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder private var folderList: some View {
        if let folders {
            if folders.isEmpty {
                Text("No photos or videos found near the top. Use “Choose a folder…”.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.subtle)
                    .padding(.vertical, 8)
            } else if folders.count > 1 {
                FolderRow(
                    icon: "photo.stack", title: "Everything on this drive",
                    count: Self.summary(folders.map(\.photoCount).reduce(0, +), folders.map(\.videoCount).reduce(0, +)),
                    emphasis: true
                ) {
                    onOpen(folders.map(\.url), location.name)
                }
            }
            ForEach(folders) { folder in
                FolderRow(icon: "folder", title: folder.path, count: Self.summary(folder.photoCount, folder.videoCount), emphasis: false) {
                    onOpen([folder.url], folder.url.lastPathComponent)
                }
            }
        } else {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Looking for photos and videos…").font(.system(size: 12)).foregroundStyle(Theme.subtle)
            }
            .padding(.vertical, 8)
        }
    }

    private func loadFolders() async {
        guard folders == nil else { return }
        let root = location.url
        folders = await Task.detached(priority: .userInitiated) { StorageScanner.shootFolders(in: root) }.value
    }

    private func openAll() async {
        await loadFolders()
        guard let folders, !folders.isEmpty else { return }
        onOpen(folders.map(\.url), location.name)
    }

    /// "1,335 photos · 12 videos", leaving out a kind there is none of.
    static func summary(_ photos: Int, _ videos: Int) -> String {
        var parts: [String] = []
        if photos > 0 { parts.append("\(photos.formatted()) photo\(photos == 1 ? "" : "s")") }
        if videos > 0 { parts.append("\(videos.formatted()) video\(videos == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }

    private var symbol: String {
        switch location.kind {
        case .card: "sdcard.fill"
        case .drive: "externaldrive.fill"
        case .mac:
            switch location.name {
            case "Movies": "film"
            case "Desktop": "menubar.dock.rectangle"
            case "Downloads": "arrow.down.circle"
            default: "photo.on.rectangle.angled"
            }
        }
    }

    private var kindName: String {
        switch location.kind {
        case .card: "SD CARD"
        case .drive: "DRIVE"
        case .mac: "THIS MAC"
        }
    }

    private var usedFraction: Double? {
        guard let total = location.total, let available = location.available, total > 0 else { return nil }
        return Double(total - available) / Double(total)
    }

    private var usage: String? {
        guard let total = location.total, let available = location.available else { return nil }
        let format = ByteCountFormatter()
        format.countStyle = .file
        return "\(format.string(fromByteCount: available)) free of \(format.string(fromByteCount: total))"
    }
}

/// How full a drive is; amber past 90%.
private struct CapacityBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.raised)
                Capsule()
                    .fill(fraction > 0.9 ? Theme.warning : Theme.accent)
                    .frame(width: max(4, geometry.size.width * fraction))
            }
        }
        .accessibilityLabel("\(Int(fraction * 100))% used")
    }
}

/// A folder (or "All photos") inside an opened drive.
private struct FolderRow: View {
    let icon: String
    let title: String
    let count: String
    let emphasis: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(emphasis ? Theme.accent : Theme.subtle)
                Text(title)
                    .font(.system(size: 13, weight: emphasis ? .semibold : .regular))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(count).font(.system(size: 12)).foregroundStyle(Theme.subtle)
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
