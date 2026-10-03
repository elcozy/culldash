import SwiftUI
import CullDashCore

/// The clip as a strip of time: what is kept, what is cut, where the playhead
/// is, and the stretch currently being marked.
///
/// Dragging across it marks a section; a click without a drag moves the
/// playhead. Both actions are on the same strip because a clip is short and
/// the strip is the only place either makes sense.
struct ClipTrimBar: View {
    let edit: ClipEdit
    /// Where the playhead is, in seconds.
    let current: Double
    /// The stretch being marked, while the mouse is down and after it is let go.
    @Binding var selection: ClipRange?
    let onScrub: (Double) -> Void

    @State private var dragOrigin: Double?
    private let height = 48.0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .topLeading) {
                // Cut ground showing through: everything not kept reads as a gap.
                RoundedRectangle(cornerRadius: 4).fill(Theme.raised.opacity(0.5))

                ForEach(Array(edit.kept.enumerated()), id: \.offset) { _, part in
                    Rectangle()
                        .fill(Theme.accent.opacity(0.30))
                        .frame(width: max(1, span(part, width)))
                        .offset(x: position(part.start, width))
                }

                ForEach(Array(edit.cuts.enumerated()), id: \.offset) { _, cut in
                    CutMark()
                        .frame(width: max(2, span(cut, width)))
                        .offset(x: position(cut.start, width))
                }

                if let selection, !selection.isEmpty {
                    Rectangle()
                        .fill(Theme.accent.opacity(0.22))
                        .overlay(Rectangle().strokeBorder(Theme.accent, lineWidth: 1.5))
                        .frame(width: max(2, span(selection, width)))
                        .offset(x: position(selection.start, width))
                }

                Rectangle()
                    .fill(Theme.text)
                    .frame(width: 2)
                    .offset(x: position(current, width) - 1)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.hairline, lineWidth: 1))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let from = dragOrigin ?? time(value.startLocation.x, width)
                        dragOrigin = from
                        let to = time(value.location.x, width)
                        // Under a few pixels it is a click, not a drag, and a
                        // click should scrub rather than mark a sliver.
                        if abs(value.location.x - value.startLocation.x) < 3 {
                            selection = nil
                            onScrub(to)
                        } else {
                            selection = ClipRange(start: from, end: to)
                            onScrub(to)
                        }
                    }
                    .onEnded { _ in dragOrigin = nil }
            )
        }
        .frame(height: height)
        .accessibilityLabel("Clip timeline")
    }

    private func position(_ seconds: Double, _ width: Double) -> Double {
        guard edit.duration > 0 else { return 0 }
        return min(max(seconds / edit.duration, 0), 1) * width
    }

    private func span(_ range: ClipRange, _ width: Double) -> Double {
        position(range.end, width) - position(range.start, width)
    }

    private func time(_ x: Double, _ width: Double) -> Double {
        guard width > 0 else { return 0 }
        return min(max(x / width, 0), 1) * edit.duration
    }
}

/// A cut section: hatched, so it reads as removed rather than merely darker.
private struct CutMark: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.canvas.opacity(0.85)))
            var stripes = Path()
            var x = -size.height
            while x < size.width {
                stripes.move(to: CGPoint(x: x, y: size.height))
                stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 7
            }
            context.stroke(stripes, with: .color(Theme.subtle.opacity(0.5)), lineWidth: 1)
        }
    }
}

/// `1:04.2`, which is how long a clip is talked about.
func clipTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00.0" }
    let whole = Int(seconds)
    return String(format: "%d:%02d.%d", whole / 60, whole % 60, Int((seconds - Double(whole)) * 10))
}
