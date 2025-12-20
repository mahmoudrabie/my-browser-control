#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing .env. Run scripts/04-create-env.sh first."
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

HOST="${BROWSER_MCP_HOST:-}"
PORT="${BROWSER_MCP_PORT:-}"

if [ -z "$HOST" ] || [ -z "$PORT" ]; then
  echo "Set BROWSER_MCP_HOST and BROWSER_MCP_PORT in .env"
  exit 1
fi

if command -v nc >/dev/null 2>&1; then
  if nc -z -w 2 "$HOST" "$PORT"; then
    echo "Endpoint reachable at $HOST:$PORT"
    exit 0
  fi

  echo "Endpoint not reachable at $HOST:$PORT"
  exit 1
fi

python3 - <<PY
import socket
import sys

host = "${HOST}"
port = int("${PORT}")

try:
    with socket.create_connection((host, port), timeout=2):
        print(f"Endpoint reachable at {host}:{port}")
        sys.exit(0)
except Exception as exc:
    print(f"Endpoint not reachable at {host}:{port} ({exc})")
    sys.exit(1)
PY
