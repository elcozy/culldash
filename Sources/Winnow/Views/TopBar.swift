import SwiftUI
import WinnowCore

/// Folder, view, filters on the left; auto-advance and the hand-offs on the right.
struct TopBar: View {
    @Environment(LibraryStore.self) private var store
    @State private var confirmTrash = false

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 12) {
            IconButton(symbol: "externaldrive", help: "Back to drives") {
                Task { await store.closeFolder() }
            }

            Button {
                store.chooseFolder()
            } label: {
                Label(store.folder?.lastPathComponent ?? "Open", systemImage: "folder")
                    .lineLimit(1)
            }
            .buttonStyle(ToneButtonStyle(.ghost))
            .help("Open another folder (⌘O)")

            HStack(spacing: 2) {
                IconButton(symbol: "square.grid.2x2", help: "Grid (Space)", active: store.mode == .grid) {
                    store.mode = .grid
                }
                IconButton(symbol: "rectangle", help: "One photo (Space)", active: store.mode == .loupe) {
                    store.mode = .loupe
                }
            }

            Segmented(
                options: FlagFilter.allCases,
                selection: $store.filter.flag,
                title: \.title,
                count: { store.count($0) }
            )

            Menu {
                Picker("Rating", selection: $store.filter.minStars) {
                    ForEach(0...5, id: \.self) { stars in
                        Text(stars == 0 ? "Any rating" : "\(stars)★ and up").tag(stars)
                    }
                }
                .pickerStyle(.inline)
                Picker("Files", selection: $store.filter.kind) {
                    ForEach(KindFilter.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Text(store.filter.extraCount == 0 ? "Filters" : "Filters · \(store.filter.extraCount)")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Filter by stars, or show only RAW or only JPEG files")

            Button {
                store.groupBursts.toggle()
            } label: {
                HStack(spacing: 6) {
                    if let progress = store.burstProgress {
                        ProgressView(value: progress).progressViewStyle(.circular).controlSize(.mini)
                    } else {
                        Image(systemName: "square.stack.3d.down.right")
                    }
                    Text("Similar")
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .frame(height: 28)
                .foregroundStyle(store.groupBursts ? Theme.onAccent : Theme.text)
                .background(store.groupBursts ? Theme.accent : Theme.raised, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Group bursts and re-takes of the same shot, so you can keep one and reject the rest")

            Spacer(minLength: 8)

            Toggle("Auto-advance", isOn: $store.autoAdvance)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(Theme.accent)
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .help("Go to the next photo after a flag or rating")

            Button {
                confirmTrash = true
            } label: {
                Label("Trash \(store.rejectCount) rejects", systemImage: "trash")
            }
            .buttonStyle(ToneButtonStyle(.danger))
            .disabled(store.rejectCount == 0)
            .confirmationDialog(
                "Move \(store.rejectCount) rejects to the Trash?",
                isPresented: $confirmTrash
            ) {
                Button("Move to Trash", role: .destructive) { Task { await store.trashRejects() } }
            } message: {
                Text("Their RAW, JPEG and XMP files go to the Trash on that drive, where you can still restore them.")
            }

            SendToButton()
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
    }
}
