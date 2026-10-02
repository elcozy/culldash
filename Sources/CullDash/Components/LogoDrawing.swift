import CoreGraphics

/// The CullDash mark, drawn with Core Graphics: a fanned stack of photos on
/// the accent blue, the front one a picture with a green keeper badge.
///
/// The same function draws the logo inside the app and renders the app
/// icon (scripts/make-icon.sh compiles this file on its own), so the two
/// never drift apart. It uses only Core Graphics for that reason.
enum LogoDrawing {
    static let blue = CGColor(red: 10 / 255, green: 132 / 255, blue: 1, alpha: 1)

    /// Draws into a square of `size` points with the origin at the top-left.
    /// `iconInset` leaves the margin macOS app icons have around their tile.
    static func draw(in context: CGContext, size: CGFloat, iconInset: Bool = false) {
        let unit = size / 1024
        context.saveGState()
        // Flip to top-left origin so the numbers read like a design file.
        context.translateBy(x: 0, y: size)
        context.scaleBy(x: unit, y: -unit)

        let tile = iconInset ? CGRect(x: 100, y: 100, width: 824, height: 824) : CGRect(x: 0, y: 0, width: 1024, height: 1024)
        let radius = tile.width * 0.225
        context.addPath(CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.setFillColor(blue)
        context.fillPath()

        let scale = tile.width / 1024
        context.translateBy(x: tile.minX, y: tile.minY)
        context.scaleBy(x: scale, y: scale)

        card(context, angle: -14, alpha: 0.32)
        card(context, angle: -5, alpha: 0.58)
        card(context, angle: 6, alpha: 1)
        frontPicture(context)
        context.restoreGState()
    }

    /// One photo: a rounded rectangle turned about the tile's centre.
    private static func card(_ context: CGContext, angle: CGFloat, alpha: CGFloat) {
        context.saveGState()
        context.translateBy(x: 512, y: 540)
        context.rotate(by: angle * .pi / 180)
        let rect = CGRect(x: -230, y: -290, width: 460, height: 580)
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 54, cornerHeight: 54, transform: nil))
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
        context.fillPath()
        context.restoreGState()
    }

    static let green = CGColor(red: 48 / 255, green: 209 / 255, blue: 88 / 255, alpha: 1)

    /// The front photo's picture (sun and hills), then the keeper badge.
    private static func frontPicture(_ context: CGContext) {
        context.saveGState()
        context.translateBy(x: 512, y: 540)
        context.rotate(by: 6 * .pi / 180)

        let picture = CGRect(x: -186, y: -246, width: 372, height: 400)
        context.saveGState()
        context.addPath(CGPath(roundedRect: picture, cornerWidth: 26, cornerHeight: 26, transform: nil))
        context.clip()
        context.setFillColor(CGColor(red: 10 / 255, green: 132 / 255, blue: 1, alpha: 0.16))
        context.fill(picture)
        context.setFillColor(blue)
        context.fillEllipse(in: CGRect(x: 54, y: -186, width: 86, height: 86))
        context.move(to: CGPoint(x: -230, y: 160))
        context.addLine(to: CGPoint(x: -64, y: -40))
        context.addLine(to: CGPoint(x: 40, y: 60))
        context.addLine(to: CGPoint(x: 104, y: 0))
        context.addLine(to: CGPoint(x: 230, y: 160))
        context.closePath()
        context.fillPath()
        context.restoreGState()

        let badge = CGRect(x: 96, y: 150, width: 210, height: 210)
        context.setFillColor(blue)
        context.fillEllipse(in: badge.insetBy(dx: -22, dy: -22))
        context.setFillColor(green)
        context.fillEllipse(in: badge)
        context.move(to: CGPoint(x: 150, y: 256))
        context.addLine(to: CGPoint(x: 186, y: 292))
        context.addLine(to: CGPoint(x: 252, y: 222))
        context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.setLineWidth(30)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.restoreGState()
    }
}
