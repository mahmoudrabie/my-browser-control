#!/usr/bin/env bash
set -euo pipefail

# ChatGPT → CleanPaste → LinkedIn Workflow
#
# This script automates the three-step workflow:
# 1. Extract the last assistant message from a ChatGPT tab
# 2. Clean it using CleanPaste to remove invisible characters
# 3. Open LinkedIn post composer and paste the cleaned content
#
# Prerequisites:
# - Chrome: View → Developer → Allow JavaScript from Apple Events
# - Have the relevant tabs already open in Chrome
#
# Usage:
#   ./chatgpt-to-linkedin.sh [chatgpt_tab] [cleanpaste_tab] [linkedin_tab]
#
# Examples:
#   ./chatgpt-to-linkedin.sh              # Uses default tabs: 3, 6, 9
#   ./chatgpt-to-linkedin.sh 2 7 12       # Custom tab numbers

# Tab numbers (adjust based on your Chrome tab order)
CHATGPT_TAB="${1:-3}"
CLEANPASTE_TAB="${2:-6}"
LINKEDIN_TAB="${3:-9}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'HELP'
ChatGPT → CleanPaste → LinkedIn Workflow

USAGE:
  ./chatgpt-to-linkedin.sh [chatgpt_tab] [cleanpaste_tab] [linkedin_tab]

ARGUMENTS:
  chatgpt_tab     Tab number for ChatGPT (default: 3)
  cleanpaste_tab  Tab number for CleanPaste (default: 6)
  linkedin_tab    Tab number for LinkedIn (default: 9)

EXAMPLES:
  ./chatgpt-to-linkedin.sh              # Use defaults
  ./chatgpt-to-linkedin.sh 2 7 12       # Custom tabs

LIST TABS FIRST:
  osascript -e 'tell application "Google Chrome"
    set output to ""
    set i to 0
    repeat with t in (tabs of front window)
      set i to i + 1
      set output to output & i & ". " & (title of t) & "\n"
    end repeat
    return output
  end tell'

PREREQUISITES:
  1. Chrome: View → Developer → Allow JavaScript from Apple Events
  2. Have ChatGPT, CleanPaste, and LinkedIn tabs open
  3. Have a post ready in the ChatGPT tab

HELP
    exit 0
fi

# List current tabs
log "Current Chrome tabs:"
osascript -e '
tell application "Google Chrome"
    set output to ""
    set i to 0
    repeat with t in (tabs of front window)
        set i to i + 1
        set output to output & "  " & i & ". " & (title of t) & "\n"
    end repeat
    return output
end tell
'

echo ""
log "Using tabs: ChatGPT=#$CHATGPT_TAB, CleanPaste=#$CLEANPASTE_TAB, LinkedIn=#$LINKEDIN_TAB"
echo ""

# ============================================================================
# STEP 1: Extract from ChatGPT
# ============================================================================
log "Step 1: Extracting last post from ChatGPT tab #$CHATGPT_TAB..."

osascript -e "tell application \"Google Chrome\"
    activate
    set active tab index of front window to $CHATGPT_TAB
end tell"

sleep 1

POST_TEXT=$(osascript -e '
tell application "Google Chrome"
    set postText to execute front window'\''s active tab javascript "(() => {
        const msgs = document.querySelectorAll(\"[data-message-author-role=\\\"assistant\\\"]\");
        if (msgs.length > 0) return msgs[msgs.length - 1].innerText || \"\";
        return \"\";
    })()"
    return postText
end tell
')

if [[ -z "${POST_TEXT//[[:space:]]/}" ]]; then
    log "ERROR: No post found in ChatGPT tab. Make sure there's an assistant message visible."
    exit 1
fi

echo "$POST_TEXT" > /tmp/chatgpt_post.txt
POST_LENGTH=${#POST_TEXT}
log "✓ Extracted $POST_LENGTH characters"

# ============================================================================
# STEP 2: Clean with CleanPaste
# ============================================================================
log "Step 2: Cleaning text with CleanPaste tab #$CLEANPASTE_TAB..."

osascript -e "tell application \"Google Chrome\" to set active tab index of front window to $CLEANPASTE_TAB"

# Encode to base64 for safe transmission
TEXT_B64=$(cat /tmp/chatgpt_post.txt | python3 -c 'import base64,sys; print(base64.b64encode(sys.stdin.read().encode("utf-8")).decode("ascii"))')

sleep 1

# Paste and click clean
osascript -e "
tell application \"Google Chrome\"
    execute front window's active tab javascript \"(() => {
        const bytes = Uint8Array.from(atob('$TEXT_B64'), c => c.charCodeAt(0));
        const text = new TextDecoder('utf-8').decode(bytes);
        const ta = document.querySelector('textarea');
        if (ta) { 
            ta.value = text; 
            ta.dispatchEvent(new Event('input', {bubbles:true})); 
        }
        const btn = Array.from(document.querySelectorAll('button')).find(b => 
            (b.textContent||'').toLowerCase().includes('clean')
        );
        if (btn) btn.click();
        return 'done';
    })()\"
end tell
"

log "✓ Pasted and clicked Clean button"

# Wait for cleaning and copy result
sleep 2

CLEANED_LENGTH=$(osascript -e '
tell application "Google Chrome"
    set cleanedText to execute front window'\''s active tab javascript "(() => {
        const tas = document.querySelectorAll(\"textarea\");
        return tas.length > 1 ? (tas[1].value || \"\") : (tas[0] ? tas[0].value : \"\");
    })()"
    set the clipboard to cleanedText
    return length of cleanedText
end tell
')

log "✓ Cleaned text copied to clipboard ($CLEANED_LENGTH characters)"

# ============================================================================
# STEP 3: Post to LinkedIn
# ============================================================================
log "Step 3: Opening LinkedIn post composer in tab #$LINKEDIN_TAB..."

osascript -e "tell application \"Google Chrome\" to set active tab index of front window to $LINKEDIN_TAB"
sleep 1

# Navigate to feed
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "https://www.linkedin.com/feed/"'
sleep 3

# Click "Start a post"
CLICK_RESULT=$(osascript -e '
tell application "Google Chrome"
    execute front window'\''s active tab javascript "(() => {
        const btn = document.querySelector(\"button[class*=\\\"share-box-feed-entry__trigger\\\"]\") ||
                    Array.from(document.querySelectorAll(\"button\")).find(b => 
                        (b.textContent||\"\").includes(\"Start a post\")
                    );
        if (btn) { btn.click(); return \"clicked\"; }
        return \"no-button\";
    })()"
end tell
')

if [[ "$CLICK_RESULT" != "clicked" ]]; then
    log "WARNING: Could not find 'Start a post' button. Please click it manually."
fi

sleep 2

# Focus editor
osascript -e '
tell application "Google Chrome"
    execute front window'\''s active tab javascript "(() => {
        const editor = document.querySelector(\"div[role=\\\"textbox\\\"][contenteditable=\\\"true\\\"]\") ||
                       document.querySelector(\"div.ql-editor[contenteditable=\\\"true\\\"]\") ||
                       document.querySelector(\"[contenteditable=\\\"true\\\"][data-placeholder]\");
        if (editor) { editor.focus(); return \"focused\"; }
        return \"no-editor\";
    })()"
end tell
'

# Paste with Cmd+V
osascript -e 'tell application "System Events" to keystroke "v" using command down'

log "✓ Pasted into LinkedIn composer"

echo ""
echo "============================================================================"
log "✅ DONE! Review your post and click 'Post' when ready."
echo "============================================================================"
echo ""
echo "Summary:"
echo "  • Source: ChatGPT tab #$CHATGPT_TAB"
echo "  • Cleaned: $CLEANED_LENGTH characters"
echo "  • Destination: LinkedIn post composer"
echo ""
echo "The cleaned text is also in your clipboard (⌘V to paste elsewhere)"
