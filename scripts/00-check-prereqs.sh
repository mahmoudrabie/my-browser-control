#!/usr/bin/env bash
set -euo pipefail

missing=0

if [ ! -d "/Applications/Google Chrome.app" ]; then
  echo "Missing: Google Chrome (expected in /Applications)"
  missing=1
fi

for cmd in open nc python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing command: $cmd"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Fix missing items and re-run."
  exit 1
fi

echo "Prereqs OK."
