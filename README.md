# CullDash

Cull RAW photo and video shoots fast on your Mac. Open a card or drive, flick
through every frame, keep the best, trash the rest, and send the keepers to
Lightroom or any editor with their stars and labels.

- Fast: shows the JPEG preview each RAW already contains (about 30 ms on a Sony a6400 file).
- No import: files stay on the card; decisions go into standard XMP sidecars.
- Similar: groups bursts and re-takes with on-device Vision; keep one, press R.
- Safe: every delete goes to the Trash and ⌘Z brings it back.
- Photos and videos from cards (including the Mac's SD slot), drives and this Mac.

## Build

Needs macOS 14+ and the Xcode Command Line Tools.

```sh
scripts/build.sh app      # builds build/CullDash.app
scripts/build.sh test     # runs the CullDashCore tests
scripts/make-icon.sh      # redraws Resources/AppIcon.icns from the logo code
scripts/diagrams.py       # renders docs/diagrams/*.puml into docs/APPFLOW.md (needs Java)
```

`scripts/build.sh` drives `swiftc` directly; `Package.swift` describes the same
targets for Xcode and `swift build`.

## Keys

| Key | Does |
| --- | --- |
| ← → ↑ ↓ | move |
| Space / Return | grid ↔ full screen |
| P / X / U | pick / reject / clear |
| 0–5 | stars |
| 6–9 | colour label |
| R | reject the rest of a similar group |
| Z | zoom to 100% |
| I | info column |
| Delete | move to Trash (⌘Z undoes) |
| ⌘-click / ⇧-click | select several |

## Layout

- `Sources/CullDashCore`: files, previews, XMP, grouping (no UI).
- `Sources/CullDash`: the SwiftUI app.
- `site/`: the landing page (Next.js, `pnpm dev`).
- `docs/APPFLOW.md`: how it works, with PlantUML diagrams.
