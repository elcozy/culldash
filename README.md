# CullDash

**A fast, free photo and video culler for the Mac.** Plug in a card, flick
through every frame, keep the best and trash the rest. Then send the keepers
to Lightroom, Capture One or any editor with their stars and colour labels
already on them.

CullDash is for photographers who come home with hundreds or thousands of RAW
files and want to get down to the good ones before opening an editor. It does
not import, copy or catalogue anything. It reads the files where they are and
writes your decisions into standard XMP sidecars that every editor understands.

[**Download for Mac**](https://github.com/elcozy/sortRaw.app/releases/latest) ·
[Website](https://culldash.vercel.app) ·
[How it works](docs/APPFLOW.md)

## Why CullDash

- **Fast.** Shows the JPEG preview each RAW file already carries instead of
  decoding the RAW, about 30 ms per frame on a Sony a6400 file. Holding an
  arrow key flies through a shoot.
- **No import.** Files stay on the card or drive. Picks, rejects, stars and
  labels go into `.xmp` sidecars beside them, so Lightroom, Capture One,
  Bridge and darktable read them straight away.
- **Similar shots grouped.** Bursts and re-takes are grouped on-device with
  Apple's Vision framework. Keep the best one and press **R** to reject the rest.
- **Exact duplicates found.** Byte-for-byte copies are found in seconds, even on
  a full card, and one copy of each is kept.
- **Safe.** Deleting moves files to that drive's Trash, with their JPEG and
  sidecar, and ⌘Z brings them back.
- **Photos and video.** RAW, JPEG, HEIC and clips from cards (including the
  Mac's SD slot), external drives and folders on your Mac. Clips can be
  trimmed without re-encoding.
- **Private.** Everything runs on your Mac. No account, no upload, no tracking.
- **Keyboard first.** Every decision is one key (see [Keys](#keys)).

## Install

You need macOS 14 (Sonoma) or later. The download is a universal app: the same
file runs natively on Apple silicon and Intel Macs.

1. Open the [latest release](https://github.com/elcozy/sortRaw.app/releases/latest)
   and download **CullDash-x.y.z.dmg**. The **.zip** holds the same app.
2. Open the DMG and drag **CullDash** onto **Applications**.
3. Builds are not notarized by Apple yet, so the first time macOS says
   *"CullDash is damaged and can't be opened."* This is how macOS treats an
   unsigned download, not a broken file. Run this once in Terminal:

    ```sh
    xattr -dr com.apple.quarantine /Applications/CullDash.app
    ```

4. Open CullDash. When it first reads a card, drive or your Desktop, macOS asks
   for permission. Click **Allow**.

Prefer to build it yourself? See [Build from source](#build-from-source).

## Use it

1. Pick a card or drive on the start screen, then a folder (or **Open all**).
2. Move with the arrow keys. **Return** switches between the grid and full screen.
3. **P** picks, **X** rejects, **0–5** sets stars, **6–9** sets a colour label.
4. Press **Delete** to send rejects to the Trash, or use **Send to…** to open
   the keepers in your editor.

## Keys

| Key | Does |
| --- | --- |
| ← → ↑ ↓ | move |
| Return | grid ↔ full screen |
| Space | grid ↔ full screen, or play/pause on a clip |
| P / X / U | pick / reject / clear |
| 0–5 | stars |
| 6–9 | colour label |
| R | reject the rest of a similar group |
| Z | zoom to 100% |
| I | info column |
| Delete | move to Trash (⌘Z undoes) |
| ⌘-click / ⇧-click | select several |

## Trimming clips

Open a video full screen and it plays like any other clip: **Space** plays and
pauses rather than leaving the view. The pencil button under it starts editing,
which brings out a row of pieces; until then the row stays out of the way.

It works the way a video editor does. Scrub along the row, **split** at the
playhead, click a piece to pick it, and **drop** it — what is left closes up,
and the player immediately plays the result rather than the original, so what
you see is what will be written.

- **scissors** — split the clip at the playhead
- **trash** — drop the picked piece; the rest close up
- **arrow** — put the whole clip back
- **xmark** — stop editing
- **save** — write it as a new clip, or in the original's place

Splitting on its own changes nothing, so saving stays unavailable until a piece
is actually dropped.

Saving copies the original streams rather than re-encoding, so it is quick and
loses no quality. In exchange each cut lands on the keyframe before the mark,
which on long-GOP footage can be up to a second early; QuickTime trims the same
way. Replacing the original sends it to that drive's Trash and adds it to the
undo history, so ⌘Z brings the full-length clip back.

Saving as a new clip adds it to the shoot straight away, right beside the clip
it came from and carrying its flag, rating and label over, so going back to the
grid shows it where you would expect rather than leaving it to be found on the
card later.

## Exact duplicates

**Duplicates** in the tool strip narrows the shoot to photos whose files are
byte for byte the same, and **Keep one of each** rejects every copy but one —
the one you picked, if you picked one. The usual Trash button then takes them
all together, and ⌘Z brings them back.

Only identical files count. Two frames of the same scene are not duplicates
however alike they look; **Similar** is for those. Checking is done in three
passes — length, then 64 KB from each end, then the whole file for the few that
still agree — so a 63 GB card takes about forty seconds rather than the nine
minutes reading all of it would.

## Sharing

Viewing a photo or a clip full screen, the share button sits over its top right
corner; in the info column it sits beside **Show in Finder**. Both open the
Mac's own share menu — AirDrop, Messages, Add to Photos, and whatever else is
installed.

Sharing hands over every file of the photo, so a RAW's camera JPEG goes with it.
With several photos selected it shares all of them.

## Build from source

You need macOS 14 or later and the Xcode Command Line Tools
(`xcode-select --install` if you don't have them). Full Xcode is not needed.

```sh
git clone https://github.com/elcozy/sortRaw.app.git culldash
cd culldash
scripts/build.sh app          # makes build/CullDash.app (about a minute the first time)
open build/CullDash.app
```

`scripts/build.sh install` builds it and copies it into `/Applications`. Quit
CullDash first if it is open, or the running copy stays the old one.

Other scripts:

```sh
scripts/build.sh test     # runs the CullDashCore tests
scripts/package.sh        # builds build/CullDash-<version>.dmg
scripts/package.sh zip    # builds build/CullDash-<version>.zip
scripts/release.sh        # publishes both as a GitHub release (see below)
scripts/make-icon.sh      # redraws Resources/AppIcon.icns from the logo code
scripts/diagrams.py       # renders docs/diagrams/*.puml into docs/APPFLOW.md (needs Java)
```

`scripts/build.sh app` builds for your Mac's own chip, which is quickest.
`ARCHS="arm64 x86_64" scripts/build.sh app` builds a universal app instead, and
`scripts/package.sh` always does. `scripts/build.sh` drives `swiftc` directly. `Package.swift` describes the same
targets for Xcode and `swift build`.

For testing, `build/CullDash.app/Contents/MacOS/CullDash -folder <path>` opens a
folder straight away, `-mode loupe` goes straight to the full-screen view, and
`-appearance light` or `dark` pins the look.

### Project layout

- `Sources/CullDashCore`: files, previews, XMP, grouping (no UI).
- `Sources/CullDash`: the SwiftUI app.
- `Tests/`: tests for CullDashCore.
- `site/`: the landing page (Next.js), deployed on Vercel.
- `docs/APPFLOW.md`: how it works, with PlantUML diagrams.

## Releasing

Releases live on [GitHub Releases](https://github.com/elcozy/sortRaw.app/releases),
each with the app as a DMG, as a zip and a SHA-256 checksum file.

1. Bump `CFBundleShortVersionString` (and `CFBundleVersion`) in
   `Resources/Info.plist`, commit and push.
2. Run `scripts/release.sh` (or `scripts/release.sh --draft` to check it
   before it goes live).

The script builds both files, tags `v<version>`, pushes the tag and creates the
release with install notes. You need the GitHub CLI signed in (`gh auth status`).

### Signing and notarizing

By default the app is ad-hoc signed, which is why downloaders need the `xattr`
step above. With a paid Apple Developer account, the release opens on any Mac
with no warning:

```sh
# One time: store an app-specific password for notarytool.
xcrun notarytool store-credentials culldash \
  --apple-id you@example.com --team-id TEAMID --password <app-specific-password>

# One time: say which certificate and profile to use.
cp .env.example .env    # then edit it
```

`.env` is gitignored, and `.env.example` documents both settings. With them set,
`scripts/package.sh` and `scripts/release.sh` sign with the hardened runtime,
notarize with Apple and staple the result. `security find-identity -v -p
codesigning` lists the identities you have.

## Run the website

The landing page lives in `site/`. You need Node 20+ and pnpm.

```sh
cd site
pnpm install    # first time only
pnpm dev        # then open http://localhost:3000
```

It is deployed on Vercel with `site/` as the project's root directory.

## Contributing

Issues and pull requests are welcome. For anything bigger than a small fix,
open an issue first so we can agree on the approach. Please run
`scripts/build.sh test` before sending a change, and keep
[docs/APPFLOW.md](docs/APPFLOW.md) in step when a flow changes.

## License

[MIT](LICENSE) © 2026 Chiemeka Madufor. Lightroom, Capture One and Photoshop
are trademarks of their owners.
