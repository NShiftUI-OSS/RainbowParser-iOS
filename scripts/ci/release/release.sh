#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/helpers.sh"

ci_banner "job release"
require_env TAG VERSION BRANCH GH_TOKEN
require_cmd gh
cd "$REPO_ROOT"

log_step "gh release create ${TAG}"
gh release create "$TAG" \
  --repo "${GITHUB_REPOSITORY:?}" \
  --title "$TAG" \
  --notes "Source package ${VERSION} from branch \`${BRANCH}\`. No binary is attached; consumers resolve the git tag."
log_ok "GitHub Release ${TAG} published"
