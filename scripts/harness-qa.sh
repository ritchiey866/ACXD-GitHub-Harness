#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_REPO_SSH:?Git SSH repository required}"
: "${GIT_SHA:?Approved Git commit SHA required}"
: "${ACXD_API_KEY:?QA ACXD API key required}"
: "${ACXD_WORKSPACE_ID:?QA ACXD workspace required}"
: "${QA_MAPPING_JSON:?Harness secret with QA mapping JSON required}"
[[ "$GIT_SHA" =~ ^[0-9a-fA-F]{40}$ ]] || { echo 'GIT_SHA must be complete 40-char SHA' >&2; exit 1; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
git clone --no-checkout "$GITHUB_REPO_SSH" "$WORK/repo"
cd "$WORK/repo"
git fetch --depth 1 origin "$GIT_SHA" || true
git checkout --detach "$GIT_SHA"
[[ "$(git rev-parse HEAD)" == "$GIT_SHA" ]] || { echo 'Git SHA mismatch' >&2; exit 1; }
mkdir -p config
printf '%s' "$QA_MAPPING_JSON" > config/qa.mapping.json
chmod 600 config/qa.mapping.json
if [ -f package-lock.json ]; then npm ci; else npm install --no-audit --no-fund; fi
node scripts/acxd.mjs validate
QA_MAPPING_FILE=config/qa.mapping.json node scripts/acxd.mjs deploy --dry-run
CONFIRM_QA_DEPLOY=YES QA_MAPPING_FILE=config/qa.mapping.json node scripts/acxd.mjs deploy
