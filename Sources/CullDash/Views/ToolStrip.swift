import SwiftUI
import CullDashCore

/// The second layer under the window bar: how photos are shown and which
/// ones, on the left; trashing the rejects on the right.
struct ToolStrip: View {
    @Environment(LibraryStore.self) private var store
    @State private var confirmTrash = false

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 12) {
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
            .fixedSize()

            FiltersMenu()

            SimilarToggle()

            Spacer(minLength: 8)

            if store.selectedIDs.count > 1 {
                Text("\(store.selectedIDs.count) selected").font(.system(size: 12, weight: .semibold))
                Button("Clear") { store.clearSelection() }
                    .buttonStyle(ToneButtonStyle(.ghost))
                    .help("Select just one photo again (Esc)")
            }

            IconButton(symbol: "info.circle", help: "Info (I)", active: store.showInspector) {
                store.showInspector.toggle()
            }

            Button {
                confirmTrash = true
            } label: {
                Label(store.rejectCount == 1 ? "Trash 1 reject" : "Trash \(store.rejectCount) rejects", systemImage: "trash")
            }
            .buttonStyle(ToneButtonStyle(.danger))
            .fixedSize()
            .disabled(store.rejectCount == 0)
            .confirmationDialog("Move \(store.rejectCount) rejects to the Trash?", isPresented: $confirmTrash) {
                Button("Move to Trash", role: .destructive) { Task { await store.trashRejects() } }
            } message: {
                Text("Their RAW, JPEG and XMP files go to the Trash on that drive. ⌘Z puts them back.")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }
}

/// Turns grouping of similar shots on and off, with progress while grouping.
private struct SimilarToggle: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
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
        .fixedSize()
        .help("Group bursts and re-takes of the same shot, so you can keep one and reject the rest")
    }
}
