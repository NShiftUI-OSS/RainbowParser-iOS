#!/usr/bin/env bash
# Shared by test/assemble/commit (not a GitHub job).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/helpers.sh"

ci_overlay_versioned_source() {
  log_step "overlay versioned-source"
  local src=".ci-version"
  if [[ ! -d "$src" ]]; then
    log_info "no versioned-source overlay; using checkout as-is"
    return 0
  fi
  [[ -f "${src}/RainbowParserVersion.swift" ]] || ci_die "missing ${src}/RainbowParserVersion.swift"
  [[ -f "${src}/PrinterTests.swift" ]] || ci_die "missing ${src}/PrinterTests.swift"
  cp "${src}/RainbowParserVersion.swift" Sources/RainbowParser/Public/RainbowParserVersion.swift
  cp "${src}/PrinterTests.swift" Tests/RainbowParserTests/PrinterTests.swift
  log_ok "overlaid version files onto checkout"
}
