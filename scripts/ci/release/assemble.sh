#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/helpers.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ci_banner "job assemble"
cd "$REPO_ROOT"
ci_overlay_versioned_source
require_cmd swift xcodebuild
log_step "toolchain"
xcodebuild -version
swift --version
log_step "swift build -c release"
swift build -c release
log_ok "release build validated; no binary is attached to the release"
