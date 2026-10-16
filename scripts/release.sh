#!/usr/bin/env bash
# Publishes the version in Resources/Info.plist as a GitHub release, with the
# app attached both as a DMG and as a zip.
#
#     scripts/release.sh            build both, tag v<version>, publish
#     scripts/release.sh --draft    the same, but leave the release as a draft
#
# Bump CFBundleShortVersionString in Resources/Info.plist first: the tag is
# taken from it, and the script stops if that tag already exists. Signing and
# notarizing follow the same .env settings as scripts/package.sh.
#
# Needs the GitHub CLI, signed in (`gh auth status`), and a clean checkout
# that has been pushed, so the tag points at code people can see.
set -euo pipefail
cd "$(dirname "$0")/.."

DRAFT=()
[ "${1:-}" = --draft ] && DRAFT=(--draft)

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
TAG="v$VERSION"

if [ -n "$(git status --porcelain)" ]; then
    echo "Commit or set aside your changes first: the release is built from HEAD." >&2
    exit 1
fi
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || gh release view "$TAG" >/dev/null 2>&1; then
    echo "$TAG already exists. Bump CFBundleShortVersionString in Resources/Info.plist." >&2
    exit 1
fi

scripts/package.sh zip
scripts/package.sh dmg
ZIP="build/CullDash-$VERSION.zip"
DMG="build/CullDash-$VERSION.dmg"
( cd build && shasum -a 256 "CullDash-$VERSION.zip" "CullDash-$VERSION.dmg" ) > "build/CullDash-$VERSION.sha256"

NOTES=$(mktemp)
trap 'rm -f "$NOTES"' EXIT
cat > "$NOTES" <<NOTE
## Install

Download **CullDash-$VERSION.dmg** (or the .zip), open it and drag CullDash to Applications. Needs macOS 14 or later.

NOTE
if [ -z "${NOTARY_PROFILE:-}" ]; then
    cat >> "$NOTES" <<'NOTE'
This build is not notarized by Apple yet, so macOS says it "is damaged and can't be opened" on first launch. That is how macOS treats an unsigned download, not a broken file. After moving it to Applications, run this once in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/CullDash.app
```

Then open CullDash normally.

NOTE
fi
cat >> "$NOTES" <<NOTE
Checksums are in **CullDash-$VERSION.sha256**.
NOTE

git tag -a "$TAG" -m "CullDash $VERSION"
git push origin "$TAG"
gh release create "$TAG" "$DMG" "$ZIP" "build/CullDash-$VERSION.sha256" \
    --title "CullDash $VERSION" --notes-file "$NOTES" --generate-notes --verify-tag ${DRAFT[@]+"${DRAFT[@]}"}
