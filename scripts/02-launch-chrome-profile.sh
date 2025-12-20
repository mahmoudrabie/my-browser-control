#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

PROFILE_DIR="${BROWSER_MCP_PROFILE_DIR:-$HOME/.mcp-browser-control-profile}"

mkdir -p "$PROFILE_DIR"

open -na "Google Chrome" --args --user-data-dir="$PROFILE_DIR" --new-window

echo "Chrome launched with profile: $PROFILE_DIR"
