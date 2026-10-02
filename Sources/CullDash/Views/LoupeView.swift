import SwiftUI
import CullDashCore

/// One photo as large as the window allows, its details underneath.
struct LoupeView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        if let photo = store.selected {
            VStack(spacing: 0) {
                Group {
                    if store.zoomed {
                        ZoomedImage(url: photo.primary)
                    } else {
                        PreviewImage(url: photo.primary, maxPixels: PreviewSize.full)
                            .padding(16)
                            .opacity(photo.culling.flag == .reject ? 0.45 : 1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { store.toggleZoom() }
                .overlay(alignment: .topLeading) {
                    Button {
                        store.back()
                    } label: {
                        Label(store.zoomed ? "Fit" : "Back to grid", systemImage: "chevron.left")
                    }
                    .buttonStyle(ToneButtonStyle(.secondary))
                    .help(store.zoomed ? "Back to the whole photo (Esc)" : "Back to the grid (Esc)")
                    .padding(12)
                }
                Rectangle().fill(Theme.hairline).frame(height: 1)
                PhotoInfoBar(photo: photo, position: (store.selectedIndex ?? 0) + 1, total: store.visible.count)
            }
            .task(id: photo.id) { await prefetch(after: photo.id) }
        }
    }

    /// Loads the neighbours on both sides, nearest first, so stepping
    /// forward or back shows the next photo at once.
    private func prefetch(after id: Photo.ID) async {
        let list = store.visible
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        for step in 1...5 {
            for neighbour in [index + step, index - step] where list.indices.contains(neighbour) {
                if Task.isCancelled { return }
                _ = await PreviewImage.load(list[neighbour].primary, PreviewSize.full)
            }
        }
    }
}

/// The RAW decoded at full size and shown pixel for pixel, for checking focus.
struct ZoomedImage: View {
    let url: URL
    @State private var image: CGImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack {
            if let image {
                ScrollView([.horizontal, .vertical]) {
                    Image(decorative: image, scale: displayScale)
                }
                .defaultScrollAnchor(.center)
            } else {
                VStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Decoding RAW…").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
            }
        }
        .task(id: url) {
            image = nil
            let loaded = await Task.detached(priority: .userInitiated) {
                PreviewLoader.shared.fullResolution(for: url).map(LoadedImage.init)
            }.value
            if !Task.isCancelled { image = loaded?.image }
        }
    }
}

/// Name, decisions and exposure for the photo in view.
struct PhotoInfoBar: View {
    let photo: Photo
    let position: Int
    let total: Int
    @State private var exposure = ExposureInfo()

    var body: some View {
        HStack(spacing: 16) {
            Text(photo.name).font(.system(size: 13, weight: .semibold))
            FlagMark(flag: photo.culling.flag, size: 14)
            StarsView(rating: photo.culling.rating, size: 12)
            LabelDot(label: photo.culling.label)
            Spacer()
            ForEach(exposure.settings, id: \.self) { Text($0) }
            if let lens = exposure.lens { Text(lens).foregroundStyle(Theme.subtle) }
            if let camera = exposure.camera { Text(camera).foregroundStyle(Theme.subtle) }
            Text("\(position) / \(total)").foregroundStyle(Theme.subtle)
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.muted)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .task(id: photo.id) {
            let url = photo.primary
            exposure = await Task.detached(priority: .utility) { ExposureInfo.read(url) }.value
        }
    }
}
