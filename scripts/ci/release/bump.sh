#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/helpers.sh"

ci_banner "job bump"
require_env VERSION
cd "$REPO_ROOT"

VERSION_SWIFT="Sources/RainbowParser/Public/RainbowParserVersion.swift"
VERSION_TEST="Tests/RainbowParserTests/PrinterTests.swift"

log_step "patch working tree (no commit)"
ci_sed_inplace "s/public static let current = \"[^\"]+\"/public static let current = \"${VERSION}\"/" "$VERSION_SWIFT"
ci_sed_inplace "s/RainbowParserVersion\\.current == \"[^\"]+\"/RainbowParserVersion.current == \"${VERSION}\"/" "$VERSION_TEST"
grep -F "public static let current = \"${VERSION}\"" "$VERSION_SWIFT" >/dev/null \
  || ci_die "failed to patch ${VERSION_SWIFT}"
grep -F "RainbowParserVersion.current == \"${VERSION}\"" "$VERSION_TEST" >/dev/null \
  || ci_die "failed to patch ${VERSION_TEST}"
log_ok "patched ${VERSION_SWIFT}"
log_ok "patched ${VERSION_TEST}"

log_step "stage artifact files"
mkdir -p .ci-version
cp "$VERSION_SWIFT" .ci-version/RainbowParserVersion.swift
cp "$VERSION_TEST" .ci-version/PrinterTests.swift
log_ok "artifact dir .ci-version ready"
