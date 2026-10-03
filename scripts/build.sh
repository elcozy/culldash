#!/usr/bin/env bash
# Builds CullDash with swiftc directly, without SwiftPM.
#
#     scripts/build.sh test     build CullDashCore and run its tests
#     scripts/build.sh app      build build/CullDash.app (ad-hoc signed)
#
# Package.swift describes the same targets for Xcode and `swift build`; this
# script exists because SwiftPM can break on a half-updated Command Line
# Tools install while swiftc itself still works.
set -euo pipefail
cd "$(dirname "$0")/.."

export SDKROOT="${SDKROOT:-$(scripts/sdk.sh)}"
FRAMEWORKS=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
# Testing.framework loads lib_TestingInterop.dylib from here, and nothing on
# the default search path points at it, so the test binary is told where.
TESTING_LIBS=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
OUT=build/obj
mkdir -p "$OUT"

core() {
    local testing=()
    [ "${1:-}" = test ] && testing=(-enable-testing)
    swiftc -O -module-name CullDashCore -parse-as-library -emit-library -static ${testing[@]+"${testing[@]}"} \
        -emit-module -emit-module-path "$OUT/CullDashCore.swiftmodule" \
        $(find Sources/CullDashCore -name '*.swift') -o "$OUT/libCullDashCore.a"
}

run_tests() {
    core test
    cat > "$OUT/TestMain.swift" <<'EOF'
import Foundation
import Testing
@main struct TestMain { static func main() async { exit(await Testing.__swiftPMEntryPoint()) } }
EOF
    swiftc -module-name CullDashCoreTests -parse-as-library -I "$OUT" -L "$OUT" -lCullDashCore \
        -plugin-path /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing \
        -F "$FRAMEWORKS" -framework Testing -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
        -Xlinker -rpath -Xlinker "$TESTING_LIBS" \
        Tests/CullDashCoreTests/*.swift "$OUT/TestMain.swift" -o "$OUT/tests"
    "$OUT/tests"
}

build_app() {
    core
    swiftc -O -module-name CullDash -parse-as-library -I "$OUT" -L "$OUT" -lCullDashCore \
        $(find Sources/CullDash -name '*.swift') -o "$OUT/CullDash"
    local app=build/CullDash.app
    command rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$OUT/CullDash" "$app/Contents/MacOS/CullDash"
    cp Resources/Info.plist "$app/Contents/Info.plist"
    cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
    # Ad-hoc signature: enough to run on this Mac. Release builds are signed
    # with a Developer ID and notarized instead.
    codesign --force --sign - "$app"
    echo "Built $app"
}

case "${1:-app}" in
    test) run_tests ;;
    app) build_app ;;
    *) echo "usage: scripts/build.sh [test|app]" >&2; exit 2 ;;
esac
