# CullDash

Cull RAW photo and video shoots fast on your Mac. Open a card or drive, flick
through every frame, keep the best, trash the rest, and send the keepers to
Lightroom or any editor with their stars and labels.

- Fast: shows the JPEG preview each RAW already contains (about 30 ms on a Sony a6400 file).
- No import: files stay on the card; decisions go into standard XMP sidecars.
- Similar: groups bursts and re-takes with on-device Vision; keep one, press R.
- Safe: every delete goes to the Trash and ⌘Z brings it back.
- Photos and videos from cards (including the Mac's SD slot), drives and this Mac.

## Run the app

You need macOS 14 or later and the Xcode Command Line Tools
(`xcode-select --install` if you don't have them).

1. Get the code:

    ```sh
    git clone https://github.com/elcozy/sortRaw.app.git culldash
    cd culldash
    ```

2. Build the app:

    ```sh
    scripts/build.sh app
    ```

    This makes `build/CullDash.app` (about a minute the first time).

3. Open it:

    ```sh
    open build/CullDash.app
    ```

    Or drag `build/CullDash.app` into your Applications folder and open it from there.

4. The first time it reads a card, drive or your Desktop, macOS asks for
   permission. Click **Allow**.

5. Pick a card or drive on the start screen, then a folder (or **Open all**),
   and start culling with the keys below.

After pulling new code, run steps 2 and 3 again. Quit the open copy first (⌘Q).

## Send it to someone to test

To install it on this Mac:

```sh
scripts/build.sh install
```

That builds it and copies it into `/Applications`, leaving `build/CullDash.app`
where it is. Quit CullDash first if it is open, or the running copy stays the
old one.

Dragging it across in Finder works too, but Finder *moves* it rather than
copying, because `build/` and `/Applications` are on the same disk — so the
build folder ends up empty. Hold Option while dragging to copy instead, or just
run `scripts/build.sh app` again to put it back.

To send it to someone else:

```sh
scripts/package.sh         # build/CullDash-<version>.dmg  (~1 MB)
scripts/package.sh zip     # build/CullDash-<version>.zip  (~650 KB)
```

The DMG holds the app beside a shortcut to Applications, so the tester drags
one onto the other. The zip is smaller and opens straight to the app.

You need one or the other: an `.app` is a folder, and mail, chat apps and cloud
drives flatten folders, losing the executable bit, the symlinks and the code
signature. The zip is made with `ditto`, not `zip`, for the same reason. AirDrop
is the one exception — it carries a bundle intact on its own.

How it opens on their Mac depends on how it is signed.

**Unsigned (what you get by default).** The app is ad-hoc signed, which is
enough to run on the machine that built it and nothing more. macOS quarantines
anything downloaded, and refuses an ad-hoc signature, so the tester sees *"CullDash
is damaged and can't be opened"* — which is the message for a signature macOS
won't accept, not a broken download. Send these steps with the DMG:

1. Open the DMG and drag CullDash to Applications.
2. In Terminal: `xattr -dr com.apple.quarantine /Applications/CullDash.app`
3. Open CullDash normally.

**Signed and notarized (no warning at all).** Needs a paid Apple Developer
account. Once you have a Developer ID certificate in your keychain:

```sh
# One time: store an app-specific password for notarytool.
xcrun notarytool store-credentials culldash \
  --apple-id you@example.com --team-id TEAMID --password <app-specific-password>

# One time: say which certificate and profile to use.
cp .env.example .env    # then edit it

scripts/package.sh
```

`.env` is gitignored; `.env.example` documents both settings. They can also be
passed inline for a one-off, and anything already in the environment wins over
the file:

```sh
DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" scripts/package.sh
```

That signs with the hardened runtime, notarizes the DMG with Apple and staples
the result, so it opens on any Mac with no prompt. `security find-identity -v
-p codesigning` lists the identities you have.

## Run the website

The landing page lives in `site/`. You need Node 20+ and pnpm.

```sh
cd site
pnpm install    # first time only
pnpm dev        # then open http://localhost:3000
```

`pnpm build && pnpm start` runs the production build instead.

## Other scripts

```sh
scripts/build.sh test     # runs the CullDashCore tests
scripts/build.sh install  # builds it and copies it into /Applications
scripts/package.sh        # builds build/CullDash-<version>.dmg to hand to a tester
scripts/make-icon.sh      # redraws Resources/AppIcon.icns from the logo code
scripts/diagrams.py       # renders docs/diagrams/*.puml into docs/APPFLOW.md (needs Java)
```

`scripts/build.sh` drives `swiftc` directly; `Package.swift` describes the same
targets for Xcode and `swift build`.

For testing, `build/CullDash.app/Contents/MacOS/CullDash -folder <path>` opens a
folder straight away, `-mode loupe` goes straight to the full-screen view, and
`-appearance light` or `dark` pins the look.

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
