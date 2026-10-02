import AppKit
import SwiftUI
import WinnowCore

/// The main hand-off: opens the photos currently shown in Lightroom or any
/// other editor that reads them.
struct SendToButton: View {
    @Environment(LibraryStore.self) private var store
    @State private var open = false
    @State private var editors: [Editor] = []

    var body: some View {
        Button {
            editors = store.visible.first.map { EditorLauncher.editors(for: $0.primary) } ?? []
            open.toggle()
        } label: {
            Label("Send \(store.visible.count)", systemImage: "arrow.up.forward.app")
        }
        .fixedSize()
        .buttonStyle(ToneButtonStyle(.primary))
        .disabled(store.visible.isEmpty)
        .help("Open the photos shown here in an editor. Stars and labels go with them.")
        .popover(isPresented: $open, arrowEdge: .bottom) { panel }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Send \(store.visible.count) photos to")
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            if editors.isEmpty {
                Text("No app on this Mac opens these files.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .padding(8)
            }
            ForEach(editors) { editor in
                Button {
                    open = false
                    Task { await store.send(to: editor) }
                } label: {
                    HStack(spacing: 10) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: editor.url.path))
                            .resizable()
                            .frame(width: 22, height: 22)
                        Text(editor.name).font(.system(size: 13))
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 34)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuRowStyle())
            }
            Rectangle().fill(Theme.hairline).frame(height: 1).padding(.vertical, 6)
            Text("Stars and labels travel in XMP sidecars. Lightroom has no field for picks, so give keepers a star or label to see them there.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.subtle)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
        .padding(12)
        .frame(width: 300)
        .background(Theme.raised)
    }
}

/// A full-width row that lights up on hover, for lists inside popovers.
private struct MenuRowStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.text)
            .background(hovering || configuration.isPressed ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 6))
            .onHover { hovering = $0 }
    }
}
