import SwiftUI
import WinnowCore

/// The stars a photo has, as filled and empty stars.
struct StarsView: View {
    let rating: Int
    var size: CGFloat = 10

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Theme.warning : Theme.subtle.opacity(0.5))
            }
        }
        .accessibilityLabel("\(rating) stars")
    }
}

/// A pick (green check) or reject (red cross); nothing when undecided.
struct FlagMark: View {
    let flag: Flag
    var size: CGFloat = 12

    var body: some View {
        switch flag {
        case .pick:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent).font(.system(size: size))
                .accessibilityLabel("Pick")
        case .reject:
            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.negative).font(.system(size: size))
                .accessibilityLabel("Reject")
        case .none:
            EmptyView()
        }
    }
}

/// A small dot in the photo's colour label.
struct LabelDot: View {
    let label: ColorLabel

    var body: some View {
        if let color = Theme.color(for: label) {
            Circle().fill(color).frame(width: 8, height: 8).accessibilityLabel("\(label.rawValue) label")
        }
    }
}
