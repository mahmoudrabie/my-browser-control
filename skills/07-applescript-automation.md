# AppleScript Chrome Automation

## Prerequisites
**One-time setup:** Enable JavaScript from AppleScript in Chrome
- Menu: **View → Developer → Allow JavaScript from Apple Events**

---

## Core Commands

### 1. Open Chrome with Your Profile
```bash
osascript -e 'tell application "Google Chrome" to activate'
```

### 2. Navigate to URL
```bash
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "https://example.com"'
```

### 3. Open New Tab
```bash
osascript -e 'tell application "Google Chrome" to tell front window to make new tab with properties {URL:"https://example.com"}'
```

### 4. Switch to Tab by URL
```bash
osascript -e '
tell application "Google Chrome"
    set tabIndex to 0
    repeat with t in tabs of front window
        set tabIndex to tabIndex + 1
        if URL of t contains "example.com" then
            set active tab index of front window to tabIndex
            exit repeat
        end if
    end repeat
end tell
'
```

### 5. Get Page Title
```bash
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "document.title"'
```

### 6. Get Page Content
```bash
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "document.body.innerText"'
```

### 7. Click an Element
```bash
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "document.querySelector(\"button\").click()"'
```

### 8. Type into Input Field
```bash
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "
const input = document.querySelector(\"input\");
input.value = \"your text here\";
input.dispatchEvent(new Event(\"input\", { bubbles: true }));
"'
```

### 9. Type into Textarea
```bash
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "
const textarea = document.querySelector(\"textarea\");
textarea.value = \"your text here\";
textarea.dispatchEvent(new Event(\"input\", { bubbles: true }));
"'
```

### 10. Find Button by Text and Click
```bash
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "
Array.from(document.querySelectorAll(\"button\")).find(b => b.textContent.includes(\"Submit\")).click();
"'
```

---

## Complete Example: Clean Paste Workflow

```bash
#!/bin/bash
# Full workflow: Switch to Clean Paste, paste text, click clean, get result

TEXT="Your text to clean here"

# Switch to Clean Paste tab
osascript -e '
tell application "Google Chrome"
    set tabIndex to 0
    repeat with t in tabs of front window
        set tabIndex to tabIndex + 1
        if URL of t contains "cleanpaste" then
            set active tab index of front window to tabIndex
            exit repeat
        end if
    end repeat
end tell
'

# Paste text into textarea
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "
const textarea = document.querySelector(\"textarea\");
textarea.value = \"'"$TEXT"'\";
textarea.dispatchEvent(new Event(\"input\", { bubbles: true }));
"'

# Click Clean button
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "
Array.from(document.querySelectorAll(\"button\")).find(b => b.textContent.includes(\"Clean\")).click();
"'

sleep 2

# Get cleaned result
osascript -e 'tell application "Google Chrome" to execute front window'"'"'s active tab javascript "
document.querySelectorAll(\"textarea\")[1]?.value || document.querySelector(\"textarea\").value;
"'
```

---

## Why AppleScript > Browser MCPs

| Feature | AppleScript | Browser MCP | CDP MCP |
|---------|-------------|-------------|---------|
| Uses your profile | ✅ Yes | ✅ Yes | ❌ No |
| Switch tabs | ✅ Yes | ❌ No | ✅ Yes |
| Click/type | ✅ Yes (via JS) | ✅ Yes | ✅ Yes |
| No extension needed | ✅ Yes | ❌ No | ✅ Yes |
| Works with logins | ✅ Yes | ✅ Yes | ❌ No |

**AppleScript is the best option for automating Chrome with your existing profile!**

---

## Tips

1. **Quote escaping:** Use `'"'"'` to escape single quotes inside AppleScript
2. **Wait for page load:** Use `sleep 2` between navigation and interaction
3. **Dispatch events:** After setting `.value`, dispatch `input` event for React/Vue apps
4. **Find elements:** Use `Array.from().find()` to search by text content
5. **Multiple textareas:** Index them with `querySelectorAll("textarea")[0]` or `[1]`

---

## Workflow Script: SOTA-Posts → Clean → LinkedIn

If you already keep Chrome open with your working tabs, you can run the repo script:

```bash
scripts/08-sota-posts-to-linkedin.sh
```

It will:
- Find an existing tab matching `SOTA_TAB_HINT` (default: `SOTA-Posts`)
- Extract the last post text (best-effort DOM heuristics)
- Clean it using an existing `cleanpaste.site` tab (opens one if missing)
- Switch to an existing LinkedIn tab and fill the post composer
- Always copy the cleaned text to clipboard as fallback

Optional overrides:

```bash
SOTA_TAB_HINT="SOTA-Posts" \
LINKEDIN_TAB_HINT="linkedin.com" \
CLEAN_TAB_HINT="cleanpaste.site" \
scripts/08-sota-posts-to-linkedin.sh
```

Notes:
- LinkedIn UI changes frequently; if auto-fill fails, use ⌘V (clipboard fallback).
- For best extraction results, make sure the “last post” is visible in the SOTA tab.

---

## Three-Step Post Workflow: ChatGPT → CleanPaste → LinkedIn

This workflow extracts a post from any ChatGPT tab, cleans it, and posts to LinkedIn.

### Step 1: List Tabs and Extract Post from ChatGPT

```bash
# List all tabs to find the right one
osascript -e '
tell application "Google Chrome"
    set output to ""
    set tabIndex to 0
    repeat with t in (tabs of front window)
        set tabIndex to tabIndex + 1
        set output to output & tabIndex & ". " & (title of t) & "\n"
    end repeat
    return output
end tell
'

# Switch to your ChatGPT tab (e.g., tab 3) and extract last assistant message
osascript -e 'tell application "Google Chrome" to set active tab index of front window to 3'

sleep 1 && osascript -e '
tell application "Google Chrome"
    set postText to execute front window'\''s active tab javascript "(() => {
        const msgs = document.querySelectorAll(\"[data-message-author-role=\\\"assistant\\\"]\");
        if (msgs.length > 0) return msgs[msgs.length - 1].innerText || \"\";
        return \"\";
    })()"
    return postText
end tell
' > /tmp/extracted_post.txt
```

### Step 2: Clean with CleanPaste

```bash
# Switch to CleanPaste tab (e.g., tab 6)
osascript -e 'tell application "Google Chrome" to set active tab index of front window to 6'

# Encode text and paste into CleanPaste
TEXT_B64=$(cat /tmp/extracted_post.txt | python3 -c 'import base64,sys; print(base64.b64encode(sys.stdin.read().encode("utf-8")).decode("ascii"))')

sleep 1 && osascript -e "
tell application \"Google Chrome\"
    execute front window's active tab javascript \"(() => {
        const bytes = Uint8Array.from(atob('$TEXT_B64'), c => c.charCodeAt(0));
        const text = new TextDecoder('utf-8').decode(bytes);
        const ta = document.querySelector('textarea');
        if (ta) { ta.value = text; ta.dispatchEvent(new Event('input', {bubbles:true})); }
        const btn = Array.from(document.querySelectorAll('button')).find(b => (b.textContent||'').toLowerCase().includes('clean'));
        if (btn) btn.click();
        return 'done';
    })()\"
end tell
"

# Wait and copy cleaned result to clipboard
sleep 2 && osascript -e '
tell application "Google Chrome"
    set cleanedText to execute front window'\''s active tab javascript "(() => {
        const tas = document.querySelectorAll(\"textarea\");
        return tas.length > 1 ? (tas[1].value || \"\") : (tas[0] ? tas[0].value : \"\");
    })()"
    set the clipboard to cleanedText
    return "Copied " & (length of cleanedText) & " chars"
end tell
'
```

### Step 3: Post to LinkedIn

```bash
# Switch to LinkedIn tab and go to feed
osascript -e 'tell application "Google Chrome" to set active tab index of front window to 9'
sleep 1
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "https://www.linkedin.com/feed/"'

# Click "Start a post" button
sleep 3 && osascript -e '
tell application "Google Chrome"
    execute front window'\''s active tab javascript "(() => {
        const btn = document.querySelector(\"button[class*=\\\"share-box-feed-entry__trigger\\\"]\") ||
                    Array.from(document.querySelectorAll(\"button\")).find(b => (b.textContent||\"\").includes(\"Start a post\"));
        if (btn) { btn.click(); return \"clicked\"; }
        return \"no-button\";
    })()"
end tell
'

# Focus editor and paste with Cmd+V
sleep 2 && osascript -e '
tell application "Google Chrome"
    execute front window'\''s active tab javascript "(() => {
        const editor = document.querySelector(\"div[role=\\\"textbox\\\"][contenteditable=\\\"true\\\"]\") ||
                       document.querySelector(\"div.ql-editor[contenteditable=\\\"true\\\"]\");
        if (editor) { editor.focus(); return \"focused\"; }
        return \"no-editor\";
    })()"
end tell
'

osascript -e 'tell application "System Events" to keystroke "v" using command down'
```

### Complete One-Liner Script

Save this as `scripts/chatgpt-to-linkedin.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Usage: ./chatgpt-to-linkedin.sh <chatgpt_tab_number> <cleanpaste_tab_number> <linkedin_tab_number>
CHATGPT_TAB="${1:-3}"
CLEANPASTE_TAB="${2:-6}"
LINKEDIN_TAB="${3:-9}"

echo "Step 1: Extracting from ChatGPT tab #$CHATGPT_TAB..."
osascript -e "tell application \"Google Chrome\" to set active tab index of front window to $CHATGPT_TAB"
sleep 1
osascript -e 'tell application "Google Chrome" to execute front window'\''s active tab javascript "(() => { const msgs = document.querySelectorAll(\"[data-message-author-role=\\\"assistant\\\"]\"); return msgs.length > 0 ? msgs[msgs.length-1].innerText : \"\"; })()"' > /tmp/post.txt

echo "Step 2: Cleaning with CleanPaste tab #$CLEANPASTE_TAB..."
osascript -e "tell application \"Google Chrome\" to set active tab index of front window to $CLEANPASTE_TAB"
TEXT_B64=$(cat /tmp/post.txt | python3 -c 'import base64,sys; print(base64.b64encode(sys.stdin.read().encode("utf-8")).decode("ascii"))')
sleep 1
osascript -e "tell application \"Google Chrome\" to execute front window's active tab javascript \"(() => { const bytes = Uint8Array.from(atob('$TEXT_B64'), c => c.charCodeAt(0)); const text = new TextDecoder('utf-8').decode(bytes); const ta = document.querySelector('textarea'); if(ta){ta.value=text;ta.dispatchEvent(new Event('input',{bubbles:true}));} const btn = Array.from(document.querySelectorAll('button')).find(b=>(b.textContent||'').toLowerCase().includes('clean')); if(btn)btn.click(); return 'done'; })()\""
sleep 2
osascript -e 'tell application "Google Chrome" to set the clipboard to (execute front window'\''s active tab javascript "document.querySelectorAll(\"textarea\")[1]?.value || document.querySelector(\"textarea\")?.value || \"\"")'

echo "Step 3: Posting to LinkedIn tab #$LINKEDIN_TAB..."
osascript -e "tell application \"Google Chrome\" to set active tab index of front window to $LINKEDIN_TAB"
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "https://www.linkedin.com/feed/"'
sleep 3
osascript -e 'tell application "Google Chrome" to execute front window'\''s active tab javascript "(() => { const btn = Array.from(document.querySelectorAll(\"button\")).find(b=>(b.textContent||\"\").includes(\"Start a post\")); if(btn){btn.click();return \"clicked\";} return \"no-btn\"; })()"'
sleep 2
osascript -e 'tell application "Google Chrome" to execute front window'\''s active tab javascript "(() => { const e = document.querySelector(\"[contenteditable=\\\"true\\\"][role=\\\"textbox\\\"]\"); if(e){e.focus();return \"focused\";} return \"no-editor\"; })()"'
osascript -e 'tell application "System Events" to keystroke "v" using command down'

echo "✅ Done! Review your post and click Post when ready."
```

**Usage:**
```bash
# With default tab numbers (3, 6, 9)
./scripts/chatgpt-to-linkedin.sh

# With custom tab numbers
./scripts/chatgpt-to-linkedin.sh 2 7 12
```

---

## Production-Ready Automation Scripts

### 1. Full Automation Framework

For a complete, production-ready automation framework with advanced features:

```bash
scripts/applescript-full-automation.sh
```

**Features:**
- Comprehensive error handling and logging
- Multiple text extraction strategies
- Tab management (list, switch, find)
- Base64 text encoding for special characters
- Clipboard integration
- JSON response validation
- Customizable via environment variables

**Usage:**
```bash
# Use defaults
./applescript-full-automation.sh

# Custom URL and text
./applescript-full-automation.sh "https://cleanpaste.site" "Your text here"

# Get help
./applescript-full-automation.sh --help
```

**Documentation:** See `scripts/APPLESCRIPT-AUTOMATION-GUIDE.md` for comprehensive usage guide, patterns, and examples.

---

## Next Steps

1. **Start Simple**: Try `applescript-full-automation.sh` with default settings
2. **Read the Guide**: Check `scripts/APPLESCRIPT-AUTOMATION-GUIDE.md` for detailed patterns
3. **Customize**: Create your own automation scripts using the provided functions
4. **Share**: Contribute your automation patterns back to the project
