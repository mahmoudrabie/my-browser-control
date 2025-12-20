#!/usr/bin/env bash
set -euo pipefail

# Opens System Settings to Accessibility and Automation sections.
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"

echo "Grant permissions to Chrome and your MCP client app as needed."
