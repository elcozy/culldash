import SwiftUI
import WinnowCore

/// The window's top, in place of the standard title bar: the logo and the
/// shoot's name on the left, search in the middle, Send on the right.
/// Everything else lives one layer down, in `ToolStrip`.
struct TopBar: View {
    @Environment(LibraryStore.self) private var store
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var store = store
        ZStack {
            HStack(spacing: 10) {
                Button {
                    Task { await store.closeFolder() }
                } label: {
                    HStack(spacing: 8) {
                        LogoMark(size: 22)
                        Text(store.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 220, alignment: .leading)
                .help("Back to your drives")

                Spacer()

                SendToButton()
            }

            SearchField(text: $store.filter.search, focused: $searchFocused)
                .frame(width: 280)
                .onChange(of: store.searchRequests) { searchFocused = true }
        }
        .padding(.leading, trafficLightInset)
        .padding(.trailing, 12)
        .frame(height: topBarHeight)
    }
}

/// Search by file name. Esc clears it and hands the keys back to culling.
private struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(Theme.subtle)
            TextField("Search photos by name", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused(focused)
                .onExitCommand {
                    text = ""
                    focused.wrappedValue = false
                }
            if text.isEmpty {
                Text("⌘F").font(.system(size: 11)).foregroundStyle(Theme.subtle)
            } else {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.subtle)
                }
                .buttonStyle(.plain)
                .help("Clear the search")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.controlRadius)
                .strokeBorder(focused.wrappedValue ? Theme.accent : .clear, lineWidth: 1.5)
        )
    }
}
