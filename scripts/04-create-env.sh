#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_FILE="$ROOT_DIR/config/browser-mcp.env.example"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  echo ".env already exists: $ENV_FILE"
  exit 0
fi

cp "$EXAMPLE_FILE" "$ENV_FILE"

echo "Created .env. Fill in values from the extension UI."
