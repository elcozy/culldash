import AppKit
import CullDashCore
import SwiftUI

/// The details column on the right (Get Info, I or ⌘I): when and where a
/// photo was taken, how, and where the file is.
struct InspectorView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Info").font(.system(size: 13, weight: .bold))
                Spacer()
                IconButton(symbol: "xmark", help: "Close info (I)") { store.showInspector = false }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            Rectangle().fill(Theme.hairline).frame(height: 1)
            if let photo = store.selected {
                ScrollView { PhotoDetails(photo: photo).padding(16) }
            } else {
                Text("Select a photo to see its details.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.subtle)
                    .padding(16)
            }
        }
        .frame(width: 290)
        .background(Theme.canvas)
        .overlay(alignment: .leading) { Rectangle().fill(Theme.hairline).frame(width: 1) }
    }
}

/// The details of one photo, loaded off the main thread when it changes.
private struct PhotoDetails: View {
    let photo: Photo
    @State private var info = ExposureInfo()
    @State private var place: String?
    @State private var fileSize: Int64?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PreviewImage(url: photo.primary, maxPixels: PreviewSize.thumbnail)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 4) {
                Text(photo.name).font(.system(size: 14, weight: .semibold)).textSelection(.enabled)
                HStack(spacing: 8) {
                    FlagMark(flag: photo.culling.flag, size: 13)
                    StarsView(rating: photo.culling.rating, size: 11)
                    LabelDot(label: photo.culling.label)
                }
            }
            DetailGroup(title: "Taken") {
                Detail(icon: "calendar", text: dateText)
                if let place {
                    Detail(icon: "mappin.and.ellipse", text: place)
                } else if let coordinates = info.coordinates {
                    Detail(icon: "mappin.and.ellipse", text: coordinates)
                } else {
                    Detail(icon: "mappin.slash", text: "No location in this file", quiet: true)
                }
            }
            DetailGroup(title: "Camera") {
                if let camera = info.camera { Detail(icon: "camera", text: camera) }
                if let lens = info.lens { Detail(icon: "circle.circle", text: lens) }
                if !info.settings.isEmpty { Detail(icon: "slider.horizontal.3", text: info.settings.joined(separator: "  ·  ")) }
            }
            DetailGroup(title: "File") {
                if let width = info.pixelWidth, let height = info.pixelHeight {
                    Detail(icon: "aspectratio", text: "\(width) × \(height) · \(megapixels(width, height))")
                }
                if let fileSize {
                    Detail(icon: "doc", text: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                }
                ForEach(photo.companions, id: \.self) { Detail(icon: "doc.on.doc", text: "+ \($0.lastPathComponent)") }
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([photo.primary])
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                .buttonStyle(ToneButtonStyle(.secondary))
                .padding(.top, 4)
            }
        }
        .task(id: photo.id) { await load() }
    }

    /// The date the shutter fired, or the file's date when the photo has none.
    private var dateText: String {
        if let captured = info.captured { return captured.formatted(date: .long, time: .shortened) }
        return photo.modified.formatted(date: .long, time: .shortened) + " (file date)"
    }

    private func megapixels(_ width: Int, _ height: Int) -> String {
        String(format: "%.1f MP", Double(width * height) / 1_000_000)
    }

    private func load() async {
        let url = photo.primary
        place = nil
        info = await Task.detached(priority: .userInitiated) { ExposureInfo.read(url) }.value
        fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
        if let latitude = info.latitude, let longitude = info.longitude {
            place = await PlaceNames.shared.name(latitude: latitude, longitude: longitude)
        }
    }
}

/// A small plain-text group title with its rows under it.
private struct DetailGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.subtle)
            content
        }
    }
}

private struct Detail: View {
    let icon: String
    let text: String
    var quiet = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Theme.subtle).frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(quiet ? Theme.subtle : Theme.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
