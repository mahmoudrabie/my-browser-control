#!/usr/bin/env bash
set -euo pipefail

# SOTA-Posts -> Clean -> LinkedIn (Chrome via AppleScript)
#
# Prereqs (one-time):
# - Chrome: View → Developer → Allow JavaScript from Apple Events
# - macOS: grant Automation/Accessibility permissions if prompted
#
# This script:
# 1) Activates an already-open Chrome window
# 2) Switches to an already-open tab matching SOTA tab hint
# 3) Extracts the "last post" text (best-effort heuristics)
# 4) Switches to an already-open CleanPaste tab (or opens it if missing)
# 5) Cleans the text and captures the output
# 6) Switches to an already-open LinkedIn tab and inserts text into the composer
# 7) Always also copies the cleaned text to clipboard as a fallback

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

SOTA_TAB_HINT="${SOTA_TAB_HINT:-SOTA-Posts}"
LINKEDIN_TAB_HINT="${LINKEDIN_TAB_HINT:-linkedin.com}"
CLEAN_TAB_HINT="${CLEAN_TAB_HINT:-cleanpaste.site}"

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

b64_encode() {
  python3 - <<'PY'
import base64, sys
s = sys.stdin.read()
sys.stdout.write(base64.b64encode(s.encode('utf-8')).decode('ascii'))
PY
}

b64_decode() {
  python3 - <<'PY'
import base64, sys
b = sys.stdin.read().strip()
sys.stdout.write(base64.b64decode(b.encode('ascii')).decode('utf-8', errors='replace'))
PY
}

chrome_get_last_post_b64() {
  osascript <<'APPLESCRIPT'
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
	set u2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of u)
	set ttl2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of ttl)
	set h2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of h)
	return (u2 contains h2) or (ttl2 contains h2)
end tabMatches

on activateTabByHint(hint)
	tell application "Google Chrome"
		if (count of windows) = 0 then error "No Chrome windows open"
		set win to front window
		set tabIndex to 0
		repeat with t in (tabs of win)
			set tabIndex to tabIndex + 1
			if my tabMatches(t, hint) then
				set active tab index of win to tabIndex
				return true
			end if
		end repeat
		return false
	end tell
end activateTabByHint

on jsExtractLastPost()
	return "(() => {\n" & ¬
	"  const textOf = (el) => {\n" & ¬
	"    try {\n" & ¬
	"      if (!el) return '';\n" & ¬
	"      if (typeof el.value === 'string' && el.value.trim()) return el.value.trim();\n" & ¬
	"      const t = (el.innerText || el.textContent || '').trim();\n" & ¬
	"      return t;\n" & ¬
	"    } catch { return ''; }\n" & ¬
	"  };\n" & ¬
	"\n" & ¬
	"  const pickLastNonEmpty = (nodes) => {\n" & ¬
	"    const arr = Array.from(nodes || []).map(n => ({ n, t: textOf(n) })).filter(x => x.t);\n" & ¬
	"    return arr.length ? arr[arr.length - 1].t : '';\n" & ¬
	"  };\n" & ¬
	"\n" & ¬
	"  // 1) Post-like containers\n" & ¬
	"  const postNodes = document.querySelectorAll('article, [role="article"], [data-testid*="post"], .post, .Post');\n" & ¬
	"  let text = pickLastNonEmpty(postNodes);\n" & ¬
	"  let method = text ? 'post-container' : '';\n" & ¬
	"\n" & ¬
	"  // 2) Textareas (sometimes a list of drafts/posts)\n" & ¬
	"  if (!text) {\n" & ¬
	"    text = pickLastNonEmpty(document.querySelectorAll('textarea'));\n" & ¬
	"    method = text ? 'textarea' : method;\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  // 3) Contenteditable blocks\n" & ¬
	"  if (!text) {\n" & ¬
	"    text = pickLastNonEmpty(document.querySelectorAll('[contenteditable="true"]'));\n" & ¬
	"    method = text ? 'contenteditable' : method;\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  // 4) Fallback: last paragraph-ish chunk of body text\n" & ¬
	"  if (!text) {\n" & ¬
	"    const body = (document.body && (document.body.innerText || document.body.textContent) || '').trim();\n" & ¬
	"    const parts = body.split(/\n\s*\n+/).map(s => s.trim()).filter(Boolean);\n" & ¬
	"    const last = parts.length ? parts[parts.length - 1] : '';\n" & ¬
	"    text = last;\n" & ¬
	"    method = text ? 'body-last-chunk' : method;\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  const ok = Boolean(text && text.trim());\n" & ¬
	"  return JSON.stringify({ ok, method, text: text || '' });\n" & ¬
	"})()"
end jsExtractLastPost

tell application "Google Chrome"
	activate
end tell

set sotaHint to (do shell script "python3 - <<'PY'\nimport os\nprint(os.environ.get('SOTA_TAB_HINT','SOTA-Posts'))\nPY")
if my activateTabByHint(sotaHint) is false then
	error "Could not find a Chrome tab matching hint: " & sotaHint
end if

delay 0.5

tell application "Google Chrome"
	set payload to execute front window's active tab javascript (my jsExtractLastPost())
end tell

set b64 to do shell script "python3 - <<'PY'\nimport base64, json, sys\ntry:\n    obj = json.loads(sys.argv[1])\nexcept Exception:\n    obj = {\"ok\": False, \"text\": sys.argv[1]}\ntext = obj.get('text') or ''\nprint(base64.b64encode(text.encode('utf-8')).decode('ascii'))\nPY " & quoted form of payload

return b64
APPLESCRIPT
}

chrome_clean_text_b64() {
  local input_b64="$1"
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
	set u2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of u)
	set ttl2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of ttl)
	set h2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of h)
	return (u2 contains h2) or (ttl2 contains h2)
end tabMatches

on activateOrOpenTab(hint, urlToOpen)
	tell application "Google Chrome"
		if (count of windows) = 0 then error "No Chrome windows open"
		set win to front window
		set tabIndex to 0
		repeat with t in (tabs of win)
			set tabIndex to tabIndex + 1
			if my tabMatches(t, hint) then
				set active tab index of win to tabIndex
				return true
			end if
		end repeat
		-- not found: open new tab as fallback
		tell win to make new tab with properties {URL:urlToOpen}
		delay 0.5
		return true
	end tell
end activateOrOpenTab

on jsDecodeB64ToUtf8(b64)
	return "(() => {" & ¬
	"  const b64 = '" & b64 & "';" & ¬
	"  const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));" & ¬
	"  return new TextDecoder('utf-8').decode(bytes);" & ¬
	"})()"
end jsDecodeB64ToUtf8

on jsCleanPasteFlow(inputB64)
	return "(() => {\n" & ¬
	"  const bytes = Uint8Array.from(atob('" & inputB64 & "'), c => c.charCodeAt(0));\n" & ¬
	"  const text = new TextDecoder('utf-8').decode(bytes);\n" & ¬
	"  const ta = document.querySelector('textarea');\n" & ¬
	"  if (!ta) return JSON.stringify({ ok:false, reason:'no-textarea' });\n" & ¬
	"  ta.value = text;\n" & ¬
	"  ta.dispatchEvent(new Event('input', { bubbles:true }));\n" & ¬
	"\n" & ¬
	"  const btn = Array.from(document.querySelectorAll('button')).find(b => (b.textContent||'').toLowerCase().includes('clean') || (b.textContent||'').toLowerCase().includes('submit'));\n" & ¬
	"  if (btn) btn.click();\n" & ¬
	"\n" & ¬
	"  return JSON.stringify({ ok:true });\n" & ¬
	"})()"
end jsCleanPasteFlow

on jsReadCleaned()
	return "(() => {\n" & ¬
	"  const tas = Array.from(document.querySelectorAll('textarea'));\n" & ¬
	"  const t2 = tas.length > 1 ? tas[1].value : (tas[0] ? tas[0].value : '');\n" & ¬
	"  const out = (t2 || '').trim();\n" & ¬
	"  return JSON.stringify({ ok: Boolean(out), text: out });\n" & ¬
	"})()"
end jsReadCleaned

tell application "Google Chrome"
	activate
end tell

set cleanHint to (do shell script "python3 - <<'PY'\nimport os\nprint(os.environ.get('CLEAN_TAB_HINT','cleanpaste.site'))\nPY")
my activateOrOpenTab(cleanHint, "https://cleanpaste.site")

delay 1

tell application "Google Chrome"
	set _ to execute front window's active tab javascript (my jsCleanPasteFlow("${input_b64}"))
end tell

delay 2

tell application "Google Chrome"
	set outJson to execute front window's active tab javascript (my jsReadCleaned())
end tell

set outB64 to do shell script "python3 - <<'PY'\nimport base64, json, sys\nobj = json.loads(sys.argv[1])\ntext = (obj.get('text') or '')\nprint(base64.b64encode(text.encode('utf-8')).decode('ascii'))\nPY " & quoted form of outJson

return outB64
APPLESCRIPT
}

chrome_fill_linkedin_from_b64() {
  local text_b64="$1"
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
	set u2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of u)
	set ttl2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of ttl)
	set h2 to (do shell script "python3 - <<'PY'\nimport sys\nprint(sys.argv[1].lower())\nPY " & quoted form of h)
	return (u2 contains h2) or (ttl2 contains h2)
end tabMatches

on activateTabByHint(hint)
	tell application "Google Chrome"
		if (count of windows) = 0 then error "No Chrome windows open"
		set win to front window
		set tabIndex to 0
		repeat with t in (tabs of win)
			set tabIndex to tabIndex + 1
			if my tabMatches(t, hint) then
				set active tab index of win to tabIndex
				return true
			end if
		end repeat
		return false
	end tell
end activateTabByHint

on jsFillLinkedIn(b64)
	return "(() => {\n" & ¬
	"  const bytes = Uint8Array.from(atob('" & b64 & "'), c => c.charCodeAt(0));\n" & ¬
	"  const text = new TextDecoder('utf-8').decode(bytes);\n" & ¬
	"\n" & ¬
	"  const lower = (s) => (s||'').toLowerCase();\n" & ¬
	"  const byText = (sel, needle) => Array.from(document.querySelectorAll(sel)).find(el => lower(el.textContent).includes(needle));\n" & ¬
	"\n" & ¬
	"  // If composer not open, try clicking Start a post\n" & ¬
	"  const editorSelectors = [\n" & ¬
	"    'div[role="textbox"][contenteditable="true"]',\n" & ¬
	"    'div.ql-editor[contenteditable="true"]',\n" & ¬
	"    'div[contenteditable="true"][data-placeholder]'] ;\n" & ¬
	"\n" & ¬
	"  let editor = editorSelectors.map(s => document.querySelector(s)).find(Boolean);\n" & ¬
	"  if (!editor) {\n" & ¬
	"    const startBtn = byText('button, div[role="button"], a[role="button"]', 'start a post') || byText('button, div[role="button"], a[role="button"]', 'post');\n" & ¬
	"    if (startBtn) startBtn.click();\n" & ¬
	"  }\n" & ¬
	"\n" & ¬
	"  editor = editorSelectors.map(s => document.querySelector(s)).find(Boolean);\n" & ¬
	"  if (!editor) return JSON.stringify({ ok:false, reason:'no-editor-found' });\n" & ¬
	"\n" & ¬
	"  editor.focus();\n" & ¬
	"  // Clear then set text\n" & ¬
	"  try {\n" & ¬
	"    document.getSelection()?.removeAllRanges?.();\n" & ¬
	"  } catch {}\n" & ¬
	"  editor.innerText = '';\n" & ¬
	"  editor.dispatchEvent(new InputEvent('input', { bubbles:true, data:'' }));\n" & ¬
	"  editor.innerText = text;\n" & ¬
	"  editor.dispatchEvent(new InputEvent('input', { bubbles:true, data:text }));\n" & ¬
	"\n" & ¬
	"  return JSON.stringify({ ok:true });\n" & ¬
	"})()"
end jsFillLinkedIn

tell application "Google Chrome"
	activate
end tell

set linkedinHint to (do shell script "python3 - <<'PY'\nimport os\nprint(os.environ.get('LINKEDIN_TAB_HINT','linkedin.com'))\nPY")
if my activateTabByHint(linkedinHint) is false then
	error "Could not find a Chrome tab matching hint: " & linkedinHint
end if

delay 1

tell application "Google Chrome"
	set resultJson to execute front window's active tab javascript (my jsFillLinkedIn("${text_b64}"))
end tell

return resultJson
APPLESCRIPT
}

main() {
  log "Extracting last post from tab hint: $SOTA_TAB_HINT"
  local raw_b64
  raw_b64="$(SOTA_TAB_HINT="$SOTA_TAB_HINT" chrome_get_last_post_b64)"

  local raw
  raw="$(printf %s "$raw_b64" | b64_decode)"
  if [ -z "${raw//[[:space:]]/}" ]; then
    log "No text extracted from SOTA tab."
    log "Tip: make sure the last post is visible on-screen, and the tab title/URL matches SOTA_TAB_HINT."
    exit 1
  fi

  log "Cleaning text via tab hint: $CLEAN_TAB_HINT"
  local cleaned_b64
  cleaned_b64="$(CLEAN_TAB_HINT="$CLEAN_TAB_HINT" chrome_clean_text_b64 "$raw_b64")"

  local cleaned
  cleaned="$(printf %s "$cleaned_b64" | b64_decode)"

  if [ -z "${cleaned//[[:space:]]/}" ]; then
    log "Cleaner returned empty text; falling back to raw text."
    cleaned="$raw"
    cleaned_b64="$(printf %s "$cleaned" | b64_encode)"
  fi

  # Always copy to clipboard as fallback
  printf %s "$cleaned" | pbcopy
  log "Copied cleaned text to clipboard (fallback)."

  log "Filling LinkedIn composer in tab hint: $LINKEDIN_TAB_HINT"
  local li_result
  li_result="$(LINKEDIN_TAB_HINT="$LINKEDIN_TAB_HINT" chrome_fill_linkedin_from_b64 "$cleaned_b64" || true)"

  if printf %s "$li_result" | python3 - <<'PY' 2>/dev/null; then
import json, sys
obj = json.loads(sys.stdin.read() or '{}')
print('ok' if obj.get('ok') else 'fail')
PY
    :
  fi

  if echo "$li_result" | grep -q '"ok":true'; then
    log "LinkedIn composer filled. Review and click Post."
  else
    log "Could not auto-fill LinkedIn composer. Paste manually with ⌘V (text is in clipboard)."
    log "Debug: $li_result"
  fi
}

main "$@"
