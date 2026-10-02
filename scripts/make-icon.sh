#!/usr/bin/env bash
# Renders Resources/AppIcon.icns from the logo code in
# Sources/Winnow/Components/LogoDrawing.swift, so the Dock icon and the
# logo inside the app are drawn by the same function.
#
#     scripts/make-icon.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export SDKROOT="${SDKROOT:-$(scripts/sdk.sh)}"

work="$(mktemp -d)"
trap 'command rm -rf "$work"' EXIT
iconset="$work/AppIcon.iconset"
mkdir -p "$iconset"

cat > "$work/main.swift" <<'EOF'
import AppKit
let out = CommandLine.arguments[1]
// The sizes an .iconset needs: 16–512 pt at 1x and 2x.
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
        LogoDrawing.draw(in: context, size: CGFloat(pixels), iconInset: true)
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
    }
}
EOF
swiftc -O Sources/Winnow/Components/LogoDrawing.swift "$work/main.swift" -o "$work/render"
"$work/render" "$iconset"
iconutil -c icns "$iconset" -o Resources/AppIcon.icns
echo "Wrote Resources/AppIcon.icns"
