import SwiftUI
import WinnowCore

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
                        ForEach(store.visible) { photo in
                            ThumbnailCell(photo: photo, selected: photo.id == store.selectedID)
                                .id(photo.id)
                                .onTapGesture(count: 2) {
                                    store.selectedID = photo.id
                                    store.mode = .loupe
                                }
                                .onTapGesture { store.selectedID = photo.id }
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

/// One thumbnail with its flag, stars and label under it. Rejects fade back.
struct ThumbnailCell: View {
    let photo: Photo
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PreviewImage(url: photo.primary, maxPixels: 480)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .opacity(photo.culling.flag == .reject ? 0.3 : 1)
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
