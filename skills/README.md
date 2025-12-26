# Browser MCP Skills

This directory contains reusable skill patterns for Browser MCP automation.

## Skills Index

| Skill | Description | File | Status |
|-------|-------------|------|--------|
| Navigation | Page navigation, URL handling, waiting | [01-navigation.md](01-navigation.md) | ✅ |
| Interaction | Clicking, typing, form filling | [02-interaction.md](02-interaction.md) | ✅ |
| Page Analysis | Snapshots, element discovery | [03-page-analysis.md](03-page-analysis.md) | ✅ |
| Workflows | Multi-step automation patterns | [04-workflows.md](04-workflows.md) | ✅ |
| Chrome Debug Mode | Chrome debugging setup | [05-chrome-debug-mode.md](05-chrome-debug-mode.md) | ✅ |
| Browser MCP Comparison | Tool comparison | [06-browser-mcp-comparison.md](06-browser-mcp-comparison.md) | ✅ |
| AppleScript Automation | Chrome + AppleScript | [07-applescript-automation.md](07-applescript-automation.md) | ✅ |
| Chrome Tab Navigator | Tab navigation by URL | [08-chrome-tab-navigator.md](08-chrome-tab-navigator.md) | ✅ |
| Google Sheets Updater | Sheet automation | [09-google-sheets-updater.md](09-google-sheets-updater.md) | ✅ |
| LinkedIn Post Scheduler | Full LinkedIn workflow | [10-linkedin-post-scheduler.md](10-linkedin-post-scheduler.md) | ✅ |

---

## 🔬 Proven Patterns (Tested Dec 2025)

### ✅ Extract Text from ChatGPT (Works!)
**Problem**: Clicking Copy button via JS doesn't work (browser clipboard security)  
**Solution**: Extract text directly from DOM → pipe to `pbcopy`

```bash
osascript <<'EOF' | pbcopy
tell application "Google Chrome"
    tell active tab of front window
        set postText to execute javascript "
            var msgs = document.querySelectorAll('[data-message-author-role=\"assistant\"]');
            if (msgs.length > 0) {
                var lastMsg = msgs[msgs.length - 1];
                var content = lastMsg.querySelector('.markdown');
                content ? content.innerText : lastMsg.innerText;
            } else { ''; }
        "
        return postText
    end tell
end tell
EOF
```

### ✅ Navigate to Tab by URL Pattern (Works!)
```bash
osascript <<EOF
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "YOUR_PATTERN" then
                set active tab index of w to tabIndex
                set index of w to 1
                activate
                return "found"
            end if
            set tabIndex to tabIndex + 1
        end repeat
    end repeat
end tell
EOF
```

### ✅ Paste to Focused Element (Works!)
**CRITICAL**: Must activate Chrome AND focus the target element before pasting:
```bash
osascript <<'EOF'
# Step 1: Activate Chrome
tell application "Google Chrome"
    activate
    delay 0.3
    # Step 2: Focus element via JavaScript
    tell active tab of front window
        execute javascript "document.querySelector('.ql-editor').focus()"
    end tell
end tell
delay 0.3

# Step 3: Paste using process-specific keystroke
tell application "System Events"
    tell process "Google Chrome"
        keystroke "v" using command down
    end tell
end tell
EOF
```

### ❌ Click Copy Button via JS (Doesn't Work)
Browser security blocks clipboard write from JavaScript triggered via AppleScript.

### ❌ Paste Without Focus (Doesn't Work)
If Chrome isn't activated or target element isn't focused, paste goes to wrong window (e.g., Terminal).

---

## Key Concepts

### Connection Model
- Browser MCP connects to **one tab at a time** via the Chrome extension
- Use the extension popup "Connect" button to attach to the active tab
- Tool calls control only the connected tab

### Core Tools
- `browser_navigate` - Go to a URL
- `browser_snapshot` - Get accessibility tree of current page
- `browser_click` - Click an element by reference
- `browser_type` - Type text into an element
- `browser_wait` - Wait for a specified time
- `browser_screenshot` - Capture visual screenshot

### Best Practices
1. Always take a snapshot before interacting with elements
2. Use element `ref` values from snapshots for reliable targeting
3. Add waits after navigation for dynamic content to load
4. Prefer direct URL navigation over clicking when possible
5. **Extract DOM text + pbcopy** instead of clicking Copy buttons
