import SwiftUI
import CullDashCore

/// The clip as a row of pieces, flush against each other, with a white join
/// wherever it has been split.
///
/// It draws what is left, never what was taken: dropping a piece shortens the
/// row and everything after it slides left, so there is no hatched hole to
/// read past. A piece is picked by clicking it; the playhead follows the
/// pointer as it is dragged along.
struct ClipTrimBar: View {
    let edit: ClipEdit
    /// Where the playhead is, in output seconds.
    let current: Double
    /// Which piece is picked, if any.
    @Binding var selected: Int?
    let onScrub: (Double) -> Void

    private let height = 54.0
    private let joinWidth = 2.0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4).fill(Theme.raised.opacity(0.4))

                ForEach(Array(edit.pieces.enumerated()), id: \.offset) { index, piece in
                    let isPicked = selected == index
                    Rectangle()
                        .fill(Theme.accent.opacity(isPicked ? 0.5 : 0.28))
                        .overlay(
                            Rectangle().strokeBorder(
                                isPicked ? Theme.accent : .clear, lineWidth: 2)
                        )
                        .frame(width: max(1, length(piece.duration, width)))
                        .offset(x: position(edit.outputStart(of: index), width))
                        .onTapGesture { selected = isPicked ? nil : index }
                }

                // The joins, drawn over the pieces so a split reads as one cut
                // rather than two edges that happen to meet.
                ForEach(1..<max(1, edit.pieces.count), id: \.self) { index in
                    Rectangle()
                        .fill(Theme.canvas)
                        .frame(width: joinWidth)
                        .offset(x: position(edit.outputStart(of: index), width) - joinWidth / 2)
                        .allowsHitTesting(false)
                }

                Rectangle()
                    .fill(Theme.text)
                    .frame(width: 2)
                    .offset(x: position(current, width) - 1)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .allowsHitTesting(false)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.hairline, lineWidth: 1))
            .contentShape(Rectangle())
            // Dragging scrubs. Picking a piece is the tap on the piece itself,
            // so the two never fight over the same mouse-down.
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { onScrub(time($0.location.x, width)) }
            )
        }
        .frame(height: height)
        .accessibilityLabel("Clip timeline, \(edit.pieces.count) pieces")
    }

    /// Output seconds to a position along the row.
    private func position(_ seconds: Double, _ width: Double) -> Double {
        guard edit.keptDuration > 0 else { return 0 }
        return min(max(seconds / edit.keptDuration, 0), 1) * width
    }

    private func length(_ seconds: Double, _ width: Double) -> Double {
        guard edit.keptDuration > 0 else { return 0 }
        return (seconds / edit.keptDuration) * width
    }

    private func time(_ x: Double, _ width: Double) -> Double {
        guard width > 0 else { return 0 }
        return min(max(x / width, 0), 1) * edit.keptDuration
    }
}

/// `1:04.2`, which is how long a clip is talked about.
func clipTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00.0" }
    let whole = Int(seconds)
    return String(format: "%d:%02d.%d", whole / 60, whole % 60, Int((seconds - Double(whole)) * 10))
}
