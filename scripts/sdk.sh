#!/usr/bin/env bash
# Prints the path of a macOS SDK the installed Swift compiler can build with.
#
# Command Line Tools sometimes ship an SDK newer than their compiler, and then
# every build fails with "this SDK is not supported by the compiler". This
# tries the default SDK first, then the installed ones newest first, and
# prints the first that type-checks.
#
# The probe uses @State, not just `import Foundation`, because the SDKs differ
# in a way that only shows there: from macOS 27 SwiftUICore declares State as a
# macro, which needs libSwiftUIMacros.dylib in the toolchain's plugin folder.
# Command Line Tools installs have shipped without it, and then every SwiftUI
# file fails with "plugin for module 'SwiftUIMacros' not found" while a
# Foundation-only probe still passes. Older SDKs declare State as a plain
# property wrapper and build fine, so this finds one of those.
set -euo pipefail

probe="$(mktemp -d)/probe.swift"
cat > "$probe" <<'SWIFT'
import SwiftUI

struct Probe: View {
    @State private var value = 0
    var body: some View { EmptyView() }
}
SWIFT
trap 'rm -rf "$(dirname "$probe")"' EXIT

candidates=("$(xcrun --show-sdk-path 2>/dev/null || true)")
while IFS= read -r sdk; do candidates+=("$sdk"); done < <(
    ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX[0-9]*.sdk 2>/dev/null | sort -rV
)

for sdk in "${candidates[@]}"; do
    [ -d "$sdk" ] || continue
    if swiftc -sdk "$sdk" -typecheck "$probe" 2>/dev/null; then
        echo "$sdk"
        exit 0
    fi
done
echo "No macOS SDK works with this Swift compiler. Update the Command Line Tools." >&2
exit 1
