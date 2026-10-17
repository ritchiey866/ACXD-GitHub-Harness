#!/usr/bin/env bash
set -euo pipefail
: "${ACXD_API_KEY:?DEV ACXD API key required}"
: "${ACXD_WORKSPACE_ID:?DEV ACXD workspace ID required}"
: "${GITHUB_REPO_SSH:?e.g. git@github.com:company/acxd-definitions.git}"
: "${GIT_SSH_COMMAND:?Set SSH command using a deploy key}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
git clone --branch "${GIT_BRANCH:-main}" "$GITHUB_REPO_SSH" "$WORK/repo"
cd "$WORK/repo"
if [ -f package-lock.json ]; then npm ci; else npm install --no-audit --no-fund; fi
node scripts/acxd.mjs export
node scripts/acxd.mjs validate
git add apps/
if git diff --cached --quiet; then echo 'No application changes'; exit 0; fi
git -c user.name='ACXD Export Bot' -c user.email='acxd-export-bot@users.noreply.github.com' commit -m "Export ACXD DEV definitions"
git push origin "${GIT_BRANCH:-main}"
