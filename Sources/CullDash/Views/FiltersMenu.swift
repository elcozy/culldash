import SwiftUI
import CullDashCore

/// Everything that narrows the shoot beyond the flag segments and the search
/// box: stars, file kinds and cameras.
///
/// Each part narrows what the one before it left, so they stack — 3★ and up,
/// RAW, from the a6400 is one list. Within a part, ticking more than one
/// widens it: two cameras shows photos from either. The button's badge counts
/// the parts in play, and "Clear filters" drops the lot.
struct FiltersMenu: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        @Bindable var store = store
        return Menu {
            Picker("Rating", selection: $store.filter.minStars) {
                ForEach(0...5, id: \.self) { stars in
                    Text(stars == 0 ? "Any rating" : "\(stars)★ and up").tag(stars)
                }
            }
            .pickerStyle(.inline)

            Section("Files") {
                ForEach(FileKind.allCases, id: \.self) { kind in
                    Toggle(kind.title, isOn: binding(for: kind))
                }
            }

            Section(cameraSectionTitle) {
                ForEach(store.cameras, id: \.self) { camera in
                    Toggle(camera, isOn: binding(for: camera))
                }
                if store.cameras.isEmpty {
                    Text(store.isReadingCameras ? "Reading the shoot…" : "No camera recorded")
                }
            }

            Divider()
            Button("Clear filters") { store.filter.clearExtras() }
                .disabled(store.filter.isUnrestricted)
            Toggle("Auto-advance after a decision", isOn: $store.autoAdvance)
        } label: {
            Text(label)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Narrow the shoot by stars, file kind and camera. They combine; tick several in one group to widen it.")
    }

    /// "Filters · 2" once something is narrowing the list.
    private var label: String {
        let count = store.filter.extraCount
        return count == 0 ? "Filters" : "Filters · \(count)"
    }

    /// Cameras appear as the shoot is read, so the heading says when the list
    /// is still filling rather than letting it look complete too early.
    private var cameraSectionTitle: String {
        guard let progress = store.cameraProgress else { return "Camera" }
        return "Camera — reading \(Int(progress * 100))%"
    }

    /// Ticking a kind adds it; unticking the last one goes back to every kind.
    private func binding(for kind: FileKind) -> Binding<Bool> {
        Binding(
            get: { store.filter.kinds.contains(kind) },
            set: { isOn in
                if isOn {
                    store.filter.kinds.insert(kind)
                } else {
                    store.filter.kinds.remove(kind)
                }
            })
    }

    private func binding(for camera: String) -> Binding<Bool> {
        Binding(
            get: { store.filter.cameras.contains(camera) },
            set: { isOn in
                if isOn {
                    store.filter.cameras.insert(camera)
                } else {
                    store.filter.cameras.remove(camera)
                }
            })
    }
}
