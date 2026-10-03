import SwiftUI

/// The whole photo, small, with a box around the part on screen — so that
/// zoomed into a corner you still know which corner. Clicking or dragging
/// inside it moves the view there.
struct ZoomMinimap: View {
    let image: CGImage
    let controller: ZoomController
    /// The longest side of the map, in points.
    private let extent = 148.0

    var body: some View {
        let size = mapSize
        ZStack(alignment: .topLeading) {
            Image(decorative: image, scale: 1)
                .resizable()
                .frame(width: size.width, height: size.height)
                .opacity(0.55)

            // The part on screen. A viewport wider than the photo is clamped,
            // so the box never hangs over the edge of the map.
            let box = controller.viewport
            Rectangle()
                .strokeBorder(Theme.onAccent, lineWidth: 1.5)
                .background(Rectangle().fill(Theme.accent.opacity(0.22)))
                .frame(width: size.width * min(box.width, 1), height: size.height * min(box.height, 1))
                .offset(
                    x: size.width * min(max(box.minX, 0), 1 - min(box.width, 1)),
                    y: size.height * min(max(box.minY, 0), 1 - min(box.height, 1)))
                .allowsHitTesting(false)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline, lineWidth: 1))
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0).onChanged { value in
                controller.centre(
                    on: CGPoint(
                        x: min(max(value.location.x / size.width, 0), 1),
                        y: min(max(value.location.y / size.height, 0), 1)))
            }
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 3)
        .accessibilityLabel("Where you are in the photo")
    }

    /// The photo's shape, scaled so its longest side is `extent`.
    private var mapSize: CGSize {
        let width = Double(image.width)
        let height = Double(image.height)
        guard width > 0, height > 0 else { return CGSize(width: extent, height: extent) }
        let factor = extent / max(width, height)
        return CGSize(width: width * factor, height: height * factor)
    }
}

/// Zoom out, the scale, zoom in — for people who would rather press a button
/// than learn the wheel.
struct ZoomControls: View {
    let controller: ZoomController

    var body: some View {
        HStack(spacing: 2) {
            IconButton(symbol: "minus.magnifyingglass", help: "Zoom out (−)") {
                controller.zoom(by: 1 / 1.5)
            }
            Button(action: controller.actualSize) {
                Text(percentage)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .frame(width: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Back to 100%, pixel for pixel")
            IconButton(symbol: "plus.magnifyingglass", help: "Zoom in (+)") {
                controller.zoom(by: 1.5)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 30)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var percentage: String {
        "\(Int((controller.scale * 100).rounded()))%"
    }
}
