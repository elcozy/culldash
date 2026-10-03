#!/usr/bin/env bash
# Builds CullDash and wraps it up to hand to someone else.
#
#     scripts/package.sh         a .dmg: the app beside a shortcut to
#                                Applications, which is what people expect to
#                                drag onto each other.
#     scripts/package.sh zip     a .zip instead: smaller, and all some chat
#                                apps will carry. Opens to the app itself.
#
# One or the other is needed to send it anywhere. An .app is a folder, and
# mail, chat and cloud drives flatten folders: the executable bit, the symlinks
# and the signature do not survive. Both of these keep the bundle whole.
#
# Signing decides what the person on the other end sees:
#
#   Nothing set        The app is ad-hoc signed. It runs here, but macOS
#                      quarantines anything downloaded, and an ad-hoc
#                      signature does not satisfy Gatekeeper, so the tester
#                      has to open it the long way. The script prints the
#                      steps to send them.
#   DEVELOPER_ID       A "Developer ID Application: Name (TEAMID)" identity
#                      from a paid Apple Developer account. Signs with the
#                      hardened runtime, which notarizing requires.
#   NOTARY_PROFILE     A notarytool keychain profile, set up once with:
#                        xcrun notarytool store-credentials <name> \
#                          --apple-id <id> --team-id <TEAMID> \
#                          --password <app-specific-password>
#                      With this the DMG is notarized and stapled, and it
#                      opens on any Mac with no warning at all.
set -euo pipefail
cd "$(dirname "$0")/.."

# DEVELOPER_ID and NOTARY_PROFILE usually live in .env (see .env.example).
# Anything already in the environment wins, so a one-off build can override it
# without editing the file.
if [ -f .env ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*|*[!A-Za-z_]*=*) continue ;;
            *=*) ;;
            *) continue ;;
        esac
        name=${line%%=*}
        if [ -z "$(eval "printf '%s' \"\${$name:-}\"")" ]; then
            eval "export $line"
        fi
    done < .env
fi

FORMAT="${1:-dmg}"
case "$FORMAT" in
    dmg|zip) ;;
    *) echo "usage: scripts/package.sh [dmg|zip]" >&2; exit 2 ;;
esac

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
APP=build/CullDash.app
STAGE=build/dmg
DMG="build/CullDash-$VERSION.dmg"
ZIP="build/CullDash-$VERSION.zip"

scripts/build.sh app

if [ -n "${DEVELOPER_ID:-}" ]; then
    # --options runtime is the hardened runtime; --timestamp is a trusted
    # timestamp. Notarizing refuses the upload without both.
    codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "$APP"
    codesign --verify --strict --verbose=2 "$APP"
fi

if [ "$FORMAT" = zip ]; then
    # ditto, not zip(1): it keeps the resource forks, symlinks and extended
    # attributes a signed bundle needs to stay valid.
    command rm -rf "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
    ARTEFACT="$ZIP"
else
    # A plain folder with the app and a shortcut to /Applications, which is the
    # drag-to-install layout people expect.
    command rm -rf "$STAGE" "$DMG"
    mkdir -p "$STAGE"
    cp -R "$APP" "$STAGE/CullDash.app"
    ln -s /Applications "$STAGE/Applications"
    hdiutil create -volname "CullDash $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
    command rm -rf "$STAGE"
    if [ -n "${DEVELOPER_ID:-}" ]; then
        codesign --force --sign "$DEVELOPER_ID" "$DMG"
    fi
    ARTEFACT="$DMG"
fi

if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "Notarizing (a few minutes)..."
    xcrun notarytool submit "$ARTEFACT" --keychain-profile "$NOTARY_PROFILE" --wait
    # A zip cannot carry a ticket; the app inside it is stapled instead.
    if [ "$FORMAT" = zip ]; then
        xcrun stapler staple "$APP"
        command rm -rf "$ZIP"
        ditto -c -k --keepParent "$APP" "$ZIP"
    else
        xcrun stapler staple "$DMG"
    fi
    echo "Stapled. $ARTEFACT opens on any Mac with no warning."
elif [ -n "${DEVELOPER_ID:-}" ]; then
    echo "Signed but not notarized: macOS will still warn on first open."
    echo "Set NOTARY_PROFILE to finish the job."
else
    cat <<'NOTE'

Ad-hoc signed, so Gatekeeper will block it on another Mac. Send the tester
this along with the file:

  1. Open it and drag CullDash to Applications.
  2. In Terminal, run:
       xattr -dr com.apple.quarantine /Applications/CullDash.app
  3. Open CullDash normally.

Without step 2 macOS says the app "is damaged and can't be opened", which is
the message it gives for a signature it will not accept, not a real problem
with the file.

To avoid all of that, sign and notarize with a paid Apple Developer account:
see the comments at the top of this script.
NOTE
fi

echo
echo "Built $ARTEFACT ($(du -h "$ARTEFACT" | cut -f1))"
