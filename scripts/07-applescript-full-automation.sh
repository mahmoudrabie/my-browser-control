#!/usr/bin/env bash
set -euo pipefail

# Full Chrome Automation with AppleScript + JavaScript
# 
# PREREQUISITES (one-time setup):
# 1. Chrome: View → Developer → Allow JavaScript from Apple Events
# 2. macOS: Grant Automation/Accessibility permissions if prompted
#
# This script demonstrates advanced Chrome automation patterns:
# - Tab management (switch/find/create)
# - Text extraction with multiple fallback strategies
# - Form filling and interaction
# - Base64 encoding for safe text handling
# - Error handling and logging
# - Multi-page workflows
#
# USAGE:
#   ./applescript-full-automation.sh [URL] [TEXT]
# 
# EXAMPLES:
#   # Use default URL and text
#   ./applescript-full-automation.sh
#
#   # Custom URL
#   ./applescript-full-automation.sh "https://example.com"
#
#   # Custom URL and text
#   ./applescript-full-automation.sh "https://cleanpaste.site" "My text to clean"

# ============================================================================
# Configuration
# ============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# Load environment variables if available
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

# Default values
DEFAULT_URL="${DEFAULT_URL:-https://cleanpaste.site}"
DEFAULT_TEXT="${DEFAULT_TEXT:-This is test text with some content to clean}"
TARGET_URL="${1:-$DEFAULT_URL}"
TEXT_TO_PASTE="${2:-$DEFAULT_TEXT}"

# ============================================================================
# Utility Functions
# ============================================================================

log() { 
  printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*" >&2
}

log_error() {
  printf "[%s] ERROR: %s\n" "$(date +%H:%M:%S)" "$*" >&2
}

log_success() {
  printf "[%s] ✓ %s\n" "$(date +%H:%M:%S)" "$*" >&2
}

# Base64 encode text for safe transmission to AppleScript
b64_encode() {
  python3 - <<'PY'
import base64, sys
s = sys.stdin.read()
sys.stdout.write(base64.b64encode(s.encode('utf-8')).decode('ascii'))
PY
}

# Base64 decode text from AppleScript
b64_decode() {
  python3 - <<'PY'
import base64, sys
b = sys.stdin.read().strip()
try:
    sys.stdout.write(base64.b64decode(b.encode('ascii')).decode('utf-8', errors='replace'))
except Exception as e:
    sys.stderr.write(f"Decode error: {e}\n")
    sys.stdout.write(b)
PY
}

# Validate JSON response from JavaScript
validate_json() {
  python3 - <<'PY'
import json, sys
try:
    obj = json.loads(sys.stdin.read() or '{}')
    sys.exit(0 if obj.get('ok') else 1)
except Exception:
    sys.exit(1)
PY
}

# ============================================================================
# Chrome Automation Functions
# ============================================================================

# Check if Chrome is running and has windows
chrome_check_running() {
  osascript <<'APPLESCRIPT' 2>/dev/null
tell application "System Events"
    set chromeRunning to (name of processes) contains "Google Chrome"
end tell

if not chromeRunning then
    error "Chrome is not running"
end if

tell application "Google Chrome"
    if (count of windows) = 0 then
        error "No Chrome windows open"
    end if
    return "ok"
end tell
APPLESCRIPT
}

# Get list of all open tabs
chrome_list_tabs() {
  osascript <<'APPLESCRIPT'
on normalize(s)
	if s is missing value then return ""
	try
		return (s as string)
	on error
		return ""
	end try
end normalize

tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows"
    
    set output to ""
    set win to front window
    set tabIndex to 0
    
    repeat with t in (tabs of win)
        set tabIndex to tabIndex + 1
        set tabTitle to my normalize(title of t)
        set tabURL to my normalize(URL of t)
        set output to output & tabIndex & ". " & tabTitle & " - " & tabURL & "\n"
    end repeat
    
    return output
end tell
APPLESCRIPT
}

# Navigate to URL with loading wait
chrome_navigate_to() {
  local url="$1"
  local wait_seconds="${2:-3}"
  
  osascript <<APPLESCRIPT
on jsWaitForLoad()
	return "(() => { return document.readyState === 'complete' ? 'loaded' : 'loading'; })()"
end jsWaitForLoad

tell application "Google Chrome"
    activate
    
    if (count of windows) = 0 then
        make new window
        delay 1
    end if
    
    set URL of active tab of front window to "${url}"
    delay ${wait_seconds}
    
    -- Check if page loaded
    try
        set loadState to execute front window's active tab javascript (my jsWaitForLoad())
        return loadState
    on error errMsg
        return "error: " & errMsg
    end try
end tell
APPLESCRIPT
}

# Find and switch to tab by URL hint
chrome_switch_to_tab() {
  local url_hint="$1"
  
  osascript <<APPLESCRIPT
on normalize(s)
	if s is missing value then return ""
	try
		return (s as string)
	on error
		return ""
	end try
end normalize

on tabMatches(t, hint)
	set u to my normalize(URL of t)
	set ttl to my normalize(title of t)
	set h to my normalize(hint)
	if h is "" then return false
	set u2 to (do shell script "python3 -c 'import sys; print(sys.argv[1].lower())' " & quoted form of u)
	set ttl2 to (do shell script "python3 -c 'import sys; print(sys.argv[1].lower())' " & quoted form of ttl)
	set h2 to (do shell script "python3 -c 'import sys; print(sys.argv[1].lower())' " & quoted form of h)
	return (u2 contains h2) or (ttl2 contains h2)
end tabMatches

tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows open"
    
    set win to front window
    set tabIndex to 0
    
    repeat with t in (tabs of win)
        set tabIndex to tabIndex + 1
        if my tabMatches(t, "${url_hint}") then
            set active tab index of win to tabIndex
            return "switched to tab " & tabIndex
        end if
    end repeat
    
    error "No tab found matching: ${url_hint}"
end tell
APPLESCRIPT
}

# Fill textarea and submit with base64 encoded text
chrome_fill_and_submit() {
  local text_b64="$1"
  local submit_button_text="${2:-clean}"
  
  osascript <<APPLESCRIPT
on jsFillAndSubmit(b64, btnText)
	return "(() => {\n" & ¬
	"  try {\n" & ¬
	"    // Decode base64 text\n" & ¬
	"    const bytes = Uint8Array.from(atob('" & b64 & "'), c => c.charCodeAt(0));\n" & ¬
	"    const text = new TextDecoder('utf-8').decode(bytes);\n" & ¬
	"\n" & ¬
	"    // Find textarea\n" & ¬
	"    const ta = document.querySelector('textarea');\n" & ¬
	"    if (!ta) return JSON.stringify({ ok: false, reason: 'no-textarea' });\n" & ¬
	"\n" & ¬
	"    // Fill textarea\n" & ¬
	"    ta.value = text;\n" & ¬
	"    ta.dispatchEvent(new Event('input', { bubbles: true }));\n" & ¬
	"    ta.dispatchEvent(new Event('change', { bubbles: true }));\n" & ¬
	"\n" & ¬
	"    // Find and click button\n" & ¬
	"    const btnText = '" & btnText & "'.toLowerCase();\n" & ¬
	"    const btn = Array.from(document.querySelectorAll('button')).find(b => {\n" & ¬
	"      const text = (b.textContent || b.innerText || '').toLowerCase();\n" & ¬
	"      return text.includes(btnText) || text.includes('submit');\n" & ¬
	"    });\n" & ¬
	"\n" & ¬
	"    if (btn) {\n" & ¬
	"      btn.click();\n" & ¬
	"      return JSON.stringify({ ok: true, action: 'clicked' });\n" & ¬
	"    } else {\n" & ¬
	"      return JSON.stringify({ ok: true, action: 'filled-no-button' });\n" & ¬
	"    }\n" & ¬
	"  } catch (err) {\n" & ¬
	"    return JSON.stringify({ ok: false, reason: err.message });\n" & ¬
	"  }\n" & ¬
	"})()"
end jsFillAndSubmit

tell application "Google Chrome"
    set resultJson to execute front window's active tab javascript (my jsFillAndSubmit("${text_b64}", "${submit_button_text}"))
    return resultJson
end tell
APPLESCRIPT
}

# Extract text from page (checks multiple sources)
chrome_extract_text() {
  osascript <<'APPLESCRIPT'
on jsExtractText()
	return "(() => {\n" & ¬
	"  const textOf = (el) => {\n" & ¬
	"    if (!el) return '';\n" & ¬
	"    if (typeof el.value === 'string' && el.value.trim()) return el.value.trim();\n" & ¬
	"    const t = (el.innerText || el.textContent || '').trim();\n" & ¬
	"    return t;\n" & ¬
	"  };\n" & ¬
	"\n" & ¬
	"  const pickLastNonEmpty = (nodes) => {\n" & ¬
	"    const arr = Array.from(nodes || [])\n" & ¬
	"      .map(n => ({ n, t: textOf(n) }))\n" & ¬
	"      .filter(x => x.t);\n" & ¬
	"    return arr.length ? arr[arr.length - 1].t : '';\n" & ¬
	"  };\n" & ¬
	"\n" & ¬
	"  let text = '';\n" & ¬
	"  let method = '';\n" & ¬
	"\n" & ¬
	"  // 1) Try output/result textareas (usually second)\n" & ¬
	"  const tas = Array.from(document.querySelectorAll('textarea'));\n" & ¬
	"  if (tas.length > 1 && tas[1].value.trim()) {\n" & ¬
	"    text = tas[1].value.trim();\n" & ¬
	"    method = 'textarea-output';\n" & ¬
	"  } else if (tas.length && tas[0].value.trim()) {\n" & ¬
	"    text = tas[0].value.trim();\n" & ¬
	"    method = 'textarea-single';\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  // 2) Pre/code blocks (for formatted output)\n" & ¬
	"  if (!text) {\n" & ¬
	"    text = pickLastNonEmpty(document.querySelectorAll('pre, code'));\n" & ¬
	"    if (text) method = 'pre-code';\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  // 3) Contenteditable\n" & ¬
	"  if (!text) {\n" & ¬
	"    text = pickLastNonEmpty(document.querySelectorAll('[contenteditable=\"true\"]'));\n" & ¬
	"    if (text) method = 'contenteditable';\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  // 4) Output divs\n" & ¬
	"  if (!text) {\n" & ¬
	"    text = pickLastNonEmpty(document.querySelectorAll('.output, .result, [id*=\"output\"], [id*=\"result\"]'));\n" & ¬
	"    if (text) method = 'output-div';\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  // 5) Fallback to body text\n" & ¬
	"  if (!text) {\n" & ¬
	"    text = textOf(document.body);\n" & ¬
	"    method = 'body';\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  return JSON.stringify({ ok: Boolean(text), method, text: text || '' });\n" & ¬
	"})()"
end jsExtractText

tell application "Google Chrome"
    set resultJson to execute front window's active tab javascript (my jsExtractText())
    return resultJson
end tell
APPLESCRIPT
}

# Get page info (title, URL, ready state)
chrome_get_page_info() {
  osascript <<'APPLESCRIPT'
on jsGetPageInfo()
	return "(() => { return JSON.stringify({ title: document.title, url: window.location.href, readyState: document.readyState, timestamp: Date.now() }); })()"
end jsGetPageInfo

tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows"
    
    set info to execute front window's active tab javascript (my jsGetPageInfo())
    return info
end tell
APPLESCRIPT
}

# ============================================================================
# Main Workflow
# ============================================================================

main() {
  log "Starting Chrome automation workflow"
  log "Target URL: $TARGET_URL"
  
  # Check Chrome is running
  log "Checking Chrome status..."
  if ! chrome_check_running >/dev/null 2>&1; then
    log_error "Chrome is not running or has no windows open"
    log "Please start Chrome and try again"
    exit 1
  fi
  log_success "Chrome is running"
  
  # Show current tabs
  log "Current tabs:"
  chrome_list_tabs | sed 's/^/  /'
  
  # Navigate to target URL
  log "Navigating to $TARGET_URL..."
  if ! chrome_navigate_to "$TARGET_URL" 3; then
    log_error "Failed to navigate to URL"
    exit 1
  fi
  log_success "Navigation complete"
  
  # Get page info
  local page_info
  page_info="$(chrome_get_page_info)"
  log "Page loaded: $(echo "$page_info" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("title", "Unknown"))')"
  
  # Encode text to base64
  log "Preparing text (${#TEXT_TO_PASTE} characters)..."
  local text_b64
  text_b64="$(printf %s "$TEXT_TO_PASTE" | b64_encode)"
  
  # Fill form and submit
  log "Filling form and submitting..."
  local fill_result
  fill_result="$(chrome_fill_and_submit "$text_b64" "clean")"
  
  if echo "$fill_result" | validate_json; then
    log_success "Form filled and submitted"
  else
    log_error "Form submission may have failed"
    log "Response: $fill_result"
  fi
  
  # Wait for processing
  log "Waiting for processing (3 seconds)..."
  sleep 3
  
  # Extract result
  log "Extracting result..."
  local extract_result
  extract_result="$(chrome_extract_text)"
  
  local extracted_text
  extracted_text="$(echo "$extract_result" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("text", ""))')"
  
  local extract_method
  extract_method="$(echo "$extract_result" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("method", "unknown"))')"
  
  if [ -n "${extracted_text//[[:space:]]/}" ]; then
    log_success "Text extracted (method: $extract_method, ${#extracted_text} characters)"
    
    # Copy to clipboard
    printf %s "$extracted_text" | pbcopy
    log_success "Result copied to clipboard"
    
    # Output result
    echo ""
    echo "============================================================================"
    echo "RESULT:"
    echo "============================================================================"
    echo "$extracted_text"
    echo "============================================================================"
  else
    log_error "No text extracted"
    log "This might mean the page doesn't have expected output elements"
    exit 1
  fi
}

# ============================================================================
# Entry Point
# ============================================================================

# Handle --help flag
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'HELP'
Full Chrome Automation Script

USAGE:
  ./applescript-full-automation.sh [URL] [TEXT]

OPTIONS:
  URL   - Target URL to navigate to (default: https://cleanpaste.site)
  TEXT  - Text to paste into form (default: example text)

EXAMPLES:
  # Use defaults
  ./applescript-full-automation.sh

  # Custom URL
  ./applescript-full-automation.sh "https://example.com"

  # Custom URL and text
  ./applescript-full-automation.sh "https://cleanpaste.site" "My custom text"

PREREQUISITES:
  1. Enable JavaScript from Apple Events in Chrome:
     View → Developer → Allow JavaScript from Apple Events
  
  2. Grant Automation permissions when prompted by macOS

ENVIRONMENT VARIABLES:
  DEFAULT_URL   - Default URL if not specified
  DEFAULT_TEXT  - Default text if not specified

HELP
  exit 0
fi

# Run main workflow
main "$@"
