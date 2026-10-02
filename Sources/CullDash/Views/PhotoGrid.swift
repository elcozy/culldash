import AppKit
import SwiftUI
import CullDashCore

/// Every photo shown as a thumbnail; click selects, double-click opens.
struct PhotoGrid: View {
    @Environment(LibraryStore.self) private var store
    private let cellWidth: CGFloat = 200
    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let columns = max(1, Int((geometry.size.width - 32 + spacing) / (cellWidth + spacing)))
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                        spacing: spacing
                    ) {
                        ForEach(sections) { section in
                            Section {
                                ForEach(section.photos) { photo in cell(photo) }
                            } header: {
                                if let members = section.burst { BurstHeader(members: members) }
                            }
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    store.gridColumns = columns
                    if let id = store.selectedID { proxy.scrollTo(id, anchor: .center) }
                }
                .onChange(of: columns) { _, new in store.gridColumns = new }
                .onChange(of: store.selectedID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(id) }
                }
            }
        }
    }
}

extension PhotoGrid {
    private func cell(_ photo: Photo) -> some View {
        ThumbnailCell(photo: photo, selected: store.selectedIDs.contains(photo.id))
            .id(photo.id)
            .onTapGesture(count: 2) {
                store.extraSelection = []
                store.selectedID = photo.id
                store.mode = .loupe
            }
            .onTapGesture { store.click(photo.id) }
            .contextMenu { PhotoMenu(photo: photo) }
    }

    /// The photos in order, cut into sections: each group of similar shots
    /// on its own, the photos between them together. One section when
    /// grouping is off.
    private var sections: [GridSection] {
        let list = store.visible
        guard store.groupBursts, !store.burstMembers.isEmpty else {
            return [GridSection(id: "all", burst: nil, photos: list)]
        }
        var result: [GridSection] = []
        for photo in list {
            let members = store.burst(of: photo.id)
            if let last = result.last, last.burst == members {
                result[result.count - 1].photos.append(photo)
            } else {
                result.append(GridSection(id: photo.id.path, burst: members, photos: [photo]))
            }
        }
        return result
    }
}

/// Right-click on a thumbnail. Acts on the whole selection when the photo
/// is part of it, otherwise on that photo alone.
private struct PhotoMenu: View {
    @Environment(LibraryStore.self) private var store
    let photo: Photo

    var body: some View {
        let count = store.selectedIDs.contains(photo.id) ? store.selectedIDs.count : 1
        Button("Get Info") {
            focus()
            store.showInspector = true
        }
        Divider()
        Button(count > 1 ? "Pick \(count) Photos" : "Pick") { focus(); store.setFlag(.pick) }
        Button(count > 1 ? "Reject \(count) Photos" : "Reject") { focus(); store.setFlag(.reject) }
        Button("Clear Flag") { focus(); store.setFlag(.none) }
        Divider()
        Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([photo.primary]) }
        Button(count > 1 ? "Move \(count) to Trash" : "Move to Trash", role: .destructive) {
            focus()
            Task { await store.trashSelected() }
        }
    }

    /// Right-clicking outside the selection makes that photo the selection.
    private func focus() {
        guard !store.selectedIDs.contains(photo.id) else { return }
        store.extraSelection = []
        store.selectedID = photo.id
    }
}

/// A run of photos in the grid: one burst, or the singles between bursts.
struct GridSection: Identifiable {
    let id: String
    let burst: [Photo.ID]?
    var photos: [Photo]
}

/// The line above a burst: how many frames, how many picked, and the
/// one-click "keep the picks, reject the rest".
private struct BurstHeader: View {
    @Environment(LibraryStore.self) private var store
    let members: [Photo.ID]

    var body: some View {
        let picks = store.photos.filter { members.contains($0.id) && $0.culling.flag == .pick }.count
        HStack(spacing: 10) {
            Image(systemName: "square.stack.3d.down.right").foregroundStyle(Theme.muted)
            Text("Similar · \(members.count) photos").font(.system(size: 13, weight: .semibold))
            Text(picks == 0 ? "pick your keepers with P" : "\(picks) picked")
                .font(.system(size: 12))
                .foregroundStyle(picks == 0 ? Theme.subtle : Theme.positive)
            Spacer()
            Button("Reject the rest") { store.rejectRest(of: members) }
                .buttonStyle(ToneButtonStyle(.ghost))
                .disabled(picks == 0)
                .help("Reject every photo in this group that isn't picked (R)")
        }
        .padding(.top, 14)
        .padding(.bottom, 4)
        .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 1) }
    }
}

/// One thumbnail with its flag, stars and label under it. Rejects fade back.
struct ThumbnailCell: View {
    let photo: Photo
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PreviewImage(url: photo.primary, maxPixels: PreviewSize.thumbnail)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .opacity(photo.culling.flag == .reject ? 0.3 : 1)
                .overlay(alignment: .bottomLeading) {
                    if photo.kind == .video {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.black.opacity(0.55), in: Circle())
                            .padding(6)
                            .accessibilityLabel("Video")
                    }
                }
            HStack(spacing: 6) {
                FlagMark(flag: photo.culling.flag)
                StarsView(rating: photo.culling.rating, size: 9)
                Spacer(minLength: 0)
                LabelDot(label: photo.culling.label)
            }
            Text(photo.name)
                .font(.system(size: 11))
                .foregroundStyle(Theme.subtle)
                .lineLimit(1)
        }
        .padding(8)
        .background(selected ? Theme.raised : .clear, in: RoundedRectangle(cornerRadius: Theme.floatRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.floatRadius)
                .strokeBorder(selected ? Theme.accent : .clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}
