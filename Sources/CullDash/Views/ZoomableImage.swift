import AppKit
import SwiftUI

/// How far in the photo can be pushed past its own pixels, for a hard look at
/// an eyelash. Below `fitScale` there is nothing more to see.
private let maximumScale = 8.0

/// What the zoomed photo is showing, shared between the scroll view that does
/// the work and the SwiftUI views around it (the minimap, the scale readout).
@MainActor
@Observable
final class ZoomController {
    /// 1 is pixel for pixel on screen; `fitScale` is the whole photo in view.
    private(set) var scale = 1.0
    private(set) var fitScale = 1.0
    /// The part of the photo on screen, as a fraction of the whole, which is
    /// what the minimap draws its box from.
    private(set) var viewport = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// True once there is more photo than fits, so panning and the minimap
    /// have something to say.
    var isZoomedIn: Bool { viewport.width < 0.999 || viewport.height < 0.999 }

    fileprivate weak var view: ZoomScrollView?

    func zoom(by factor: Double) { view?.setScale(scale * factor, around: nil, animated: true) }
    func fit() { view?.setScale(view?.fitScale ?? 1, around: nil, animated: true) }
    func actualSize() { view?.setScale(1, around: nil, animated: true) }
    /// Used by the minimap: put this point of the photo (0–1, from the top
    /// left) in the middle of the view.
    func centre(on point: CGPoint) { view?.centre(onUnit: point) }

    fileprivate func report(scale: Double, fitScale: Double, viewport: CGRect) {
        self.scale = scale
        self.fitScale = fitScale
        self.viewport = viewport
    }
}

/// The photo at any scale between "whole thing" and 8× its pixels, scrollable,
/// pinchable and zoomable with a mouse wheel.
struct ZoomableImage: NSViewRepresentable {
    let image: CGImage
    let controller: ZoomController

    func makeNSView(context: Context) -> ZoomScrollView {
        let view = ZoomScrollView(controller: controller)
        view.show(image)
        return view
    }

    func updateNSView(_ view: ZoomScrollView, context: Context) {
        view.show(image)
    }
}

/// A scroll view that zooms rather than only scrolls.
///
/// `allowsMagnification` alone gives pinch on a trackpad and nothing at all to
/// a mouse, which is why the wheel is handled here.
final class ZoomScrollView: NSScrollView {
    private let controller: ZoomController
    private let photo = PhotoLayerView()
    private var shown: CGImage?
    /// The scale at which the whole photo is in view; the floor for zooming out.
    private(set) var fitScale = 1.0

    init(controller: ZoomController) {
        self.controller = controller
        super.init(frame: .zero)
        self.controller.view = self
        documentView = photo
        hasVerticalScroller = false
        hasHorizontalScroller = false
        drawsBackground = false
        allowsMagnification = true
        // Pinch goes through AppKit; the limits are ours.
        minMagnification = 0.01
        maxMagnification = maximumScale
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(viewportChanged),
            name: NSView.boundsDidChangeNotification, object: contentView)
        NotificationCenter.default.addObserver(
            self, selector: #selector(viewportChanged),
            name: NSScrollView.didEndLiveMagnifyNotification, object: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// A new photo starts pixel for pixel, which is what zooming is for; a
    /// photo smaller than the window starts at the size that fills it.
    func show(_ image: CGImage) {
        guard shown !== image else { return }
        shown = image
        // Laid out in points, not pixels, so magnification 1 is one image
        // pixel per screen pixel on a Retina display.
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        photo.frame = CGRect(x: 0, y: 0, width: Double(image.width) / scale, height: Double(image.height) / scale)
        photo.layer?.contents = image
        updateFitScale()
        setScale(max(fitScale, 1), around: nil, animated: false)
        centre(onUnit: CGPoint(x: 0.5, y: 0.5))
    }

    override func layout() {
        super.layout()
        let wasFitted = abs(magnification - fitScale) < 0.001
        updateFitScale()
        if wasFitted { setScale(fitScale, around: nil, animated: false) }
        viewportChanged()
    }

    private func updateFitScale() {
        let size = photo.frame.size
        guard size.width > 0, size.height > 0, bounds.width > 0 else { return }
        fitScale = min(bounds.width / size.width, bounds.height / size.height)
        minMagnification = min(fitScale, 1)
    }

    // MARK: Zooming

    /// `around` is a point in this view's own coordinates — the pointer, so
    /// the pixel under it stays put — or `nil` to hold the middle.
    func setScale(_ scale: Double, around point: CGPoint?, animated: Bool) {
        let clamped = min(max(scale, fitScale), maximumScale)
        let anchor = point.map { convert($0, to: photo) }
            ?? CGPoint(x: contentView.documentVisibleRect.midX, y: contentView.documentVisibleRect.midY)
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                animator().setMagnification(clamped, centeredAt: anchor)
            }
        } else {
            setMagnification(clamped, centeredAt: anchor)
        }
        viewportChanged()
    }

    func toggleFitAndActual() {
        setScale(abs(magnification - fitScale) < 0.001 ? 1 : fitScale, around: nil, animated: true)
    }

    func centre(onUnit point: CGPoint) {
        let size = photo.frame.size
        let visible = contentView.documentVisibleRect
        let target = CGPoint(
            x: point.x * size.width - visible.width / 2,
            y: point.y * size.height - visible.height / 2)
        contentView.scroll(to: target)
        reflectScrolledClipView(contentView)
        viewportChanged()
    }

    override func scrollWheel(with event: NSEvent) {
        let zoomHeld = event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option)
        // A trackpad sends precise deltas and should pan, the way two fingers
        // do everywhere else. A mouse wheel sends coarse ones and zooms:
        // there is no other way to zoom with a mouse, and at 100% a wheel
        // that only scrolled would be the less useful of the two.
        guard zoomHeld || !event.hasPreciseScrollingDeltas else {
            super.scrollWheel(with: event)
            return
        }
        let steps = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY / 12 : event.scrollingDeltaY
        guard steps != 0 else { return }
        let pointer = convert(event.locationInWindow, from: nil)
        setScale(magnification * exp(steps * 0.12), around: pointer, animated: false)
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            toggleFitAndActual()
            return
        }
        drag(from: event)
    }

    /// Dragging moves the photo under the pointer, as in Preview.
    private func drag(from event: NSEvent) {
        guard controller.isZoomedIn else { return }
        NSCursor.closedHand.push()
        defer { NSCursor.pop() }
        var last = convert(event.locationInWindow, from: nil)
        while let next = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]), next.type != .leftMouseUp {
            let here = convert(next.locationInWindow, from: nil)
            let origin = contentView.documentVisibleRect.origin
            contentView.scroll(
                to: CGPoint(
                    x: origin.x - (here.x - last.x) / magnification,
                    y: origin.y - (here.y - last.y) / magnification))
            reflectScrolledClipView(contentView)
            last = here
        }
        viewportChanged()
    }

    @objc private func viewportChanged() {
        let size = photo.frame.size
        guard size.width > 0, size.height > 0 else { return }
        let visible = contentView.documentVisibleRect
        controller.report(
            scale: magnification,
            fitScale: fitScale,
            viewport: CGRect(
                x: visible.minX / size.width, y: visible.minY / size.height,
                width: min(visible.width / size.width, 1), height: min(visible.height / size.height, 1))
        )
    }
}

/// Draws the photo through its layer, so scaling is the GPU's work.
private final class PhotoLayerView: NSView {
    /// Top-left origin, so the minimap's idea of "up" matches SwiftUI's.
    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.contentsGravity = .resize
        // Above its own pixels, show the pixels rather than a smooth guess:
        // that is what checking focus needs to see.
        layer?.magnificationFilter = .nearest
        layer?.minificationFilter = .trilinear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}
