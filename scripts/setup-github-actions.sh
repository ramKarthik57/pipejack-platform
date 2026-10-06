#!/usr/bin/env bash
set -e

# ==============================================================================
# PipeJack GitHub Actions CI Activation Script
# ==============================================================================
# This script copies the tested and verified continuous integration workflow
# to the standard .github/workflows/ directory.
#
# NOTE: GitHub platform security requires that any Git push or API call that
# creates or modifies files under .github/workflows/ must be authorized using
# a Personal Access Token (PAT) or OAuth token with the explicit 'workflow' scope.
# ==============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p .github/workflows
cp deployment/ci/pipejack-ci.yml .github/workflows/pipejack-ci.yml

echo "======================================================================"
echo "[+] PipeJack CI workflow successfully staged to:"
echo "    .github/workflows/pipejack-ci.yml"
echo ""
echo "[*] To activate on GitHub Actions:"
echo "    1. Ensure your git credential / PAT has the 'workflow' OAuth scope."
echo "    2. Run: git add .github/workflows/pipejack-ci.yml"
echo "    3. Run: git commit -m 'ci: activate GitHub Actions workflow'"
echo "    4. Run: git push origin main"
echo "======================================================================"
