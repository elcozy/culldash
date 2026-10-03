import AVKit
import SwiftUI
import CullDashCore

/// One photo as large as the window allows, its details underneath.
struct LoupeView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        if let photo = store.selected {
            VStack(spacing: 0) {
                Group {
                    if photo.kind == .video {
                        ClipPlayer(url: photo.primary).padding(16)
                    } else if store.zoomed {
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

/// A video clip with the system's playback controls. It starts paused, so
/// stepping through a card full of clips stays quiet.
struct ClipPlayer: View {
    let url: URL
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .clipShape(RoundedRectangle(cornerRadius: Theme.floatRadius))
            .task(id: url) {
                player.pause()
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
            .onDisappear { player.pause() }
    }
}

/// The RAW decoded at full size, to be pushed around and zoomed into for
/// checking focus. Starts pixel for pixel; the wheel, a pinch or the buttons
/// take it between the whole photo and 8× its pixels.
struct ZoomedImage: View {
    let url: URL
    @State private var image: CGImage?
    @State private var controller = ZoomController()

    var body: some View {
        ZStack {
            if let image {
                ZoomableImage(image: image, controller: controller)
                    .overlay(alignment: .bottomTrailing) {
                        HStack(alignment: .bottom, spacing: 10) {
                            ZoomControls(controller: controller)
                            if controller.isZoomedIn {
                                ZoomMinimap(image: image, controller: controller)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomTrailing)))
                            }
                        }
                        .padding(16)
                        .animation(.easeOut(duration: 0.15), value: controller.isZoomedIn)
                    }
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
    @State private var place: String?

    var body: some View {
        HStack(spacing: 16) {
            Text(photo.name).font(.system(size: 13, weight: .semibold))
            FlagMark(flag: photo.culling.flag, size: 14)
            StarsView(rating: photo.culling.rating, size: 12)
            LabelDot(label: photo.culling.label)
            Spacer()
            Text(exposure.captured.map { $0.formatted(date: .abbreviated, time: .shortened) }
                ?? photo.modified.formatted(date: .abbreviated, time: .shortened))
                .help(exposure.captured == nil ? "File date: this file has no capture date" : "Date taken")
            if let place = place ?? exposure.coordinates {
                Label(place, systemImage: "mappin.and.ellipse").lineLimit(1)
            }
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
            place = nil
            exposure = await Task.detached(priority: .utility) { ExposureInfo.read(url) }.value
            if let latitude = exposure.latitude, let longitude = exposure.longitude {
                place = await PlaceNames.shared.name(latitude: latitude, longitude: longitude)
            }
        }
    }
}
