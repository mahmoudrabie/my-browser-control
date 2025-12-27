# Browser Automation Skills

This directory contains reusable skill patterns for browser automation using AppleScript and System Events on macOS.

## ⚠️ Critical Pattern: Window Inspection First

**Every automation workflow MUST start with Chrome window/tab inspection:**

```bash
inspect_chrome_window() {
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then return "error:No Chrome windows open"
    set windowCount to count of windows
    set win to front window
    set tabCount to count of tabs of win
    set activeIdx to active tab index of win
    return "ok:" & windowCount & ":" & tabCount & ":" & activeIdx
end tell
APPLESCRIPT
}
```

## Skills Index

| Skill | Description | File | Status |
|-------|-------------|------|--------|
| Chrome Debug Mode | Chrome debugging setup | [05-chrome-debug-mode.md](05-chrome-debug-mode.md) | ✅ |
| AppleScript Automation | Chrome + AppleScript | [07-applescript-automation.md](07-applescript-automation.md) | ✅ |
| Chrome Tab Navigator | Window inspection, tab detection | [08-chrome-tab-navigator.md](08-chrome-tab-navigator.md) | ✅ |
| Google Sheets Updater | Sheet automation | [09-google-sheets-updater.md](09-google-sheets-updater.md) | ✅ |
| LinkedIn Post Scheduler | 19-step LinkedIn workflow | [10-linkedin-post-scheduler.md](10-linkedin-post-scheduler.md) | ✅ |
| LinkedIn Posts to Sheet | Activity extraction | [11-linkedin-posts-to-sheet.md](11-linkedin-posts-to-sheet.md) | ✅ |

---

## 🔬 Proven Patterns (Tested Dec 2025)

### ✅ Window Inspection (Mandatory First Step)
```bash
# Returns: ok:windowCount:tabCount:activeIdx or error:message
osascript -e '
tell application "Google Chrome"
    if (count of windows) = 0 then return "error:No Chrome windows"
    set win to front window
    return "ok:" & (count of windows) & ":" & (count of tabs of win) & ":" & (active tab index of win)
end tell
'
```

### ✅ Dynamic Tab Detection by URL Pattern
```bash
osascript -e '
tell application "Google Chrome"
    set win to front window
    repeat with i from 1 to count of tabs of win
        if URL of tab i of win contains "linkedin.com/in/" and URL of tab i of win contains "activity" then
            return i
        end if
    end repeat
    return 0
end tell
'
```

### ✅ Clipboard Content Extraction (Works on LinkedIn!)
**Problem**: JavaScript via AppleScript cannot access LinkedIn's dynamic content  
**Solution**: Use Cmd+A, Cmd+C to copy, then parse clipboard with Python

```bash
# Copy page content to clipboard
osascript -e 'tell application "System Events" to keystroke "a" using command down'
sleep 0.5
osascript -e 'tell application "System Events" to keystroke "c" using command down'
sleep 0.5

# Parse with Python
pbpaste | python3 -c "import sys; print(sys.stdin.read()[:500])"
```

### ✅ Extract Text from ChatGPT DOM
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

### ✅ Google Sheets Cell Update
```bash
# Navigate to cell (Ctrl+G)
osascript -e 'tell application "System Events" to keystroke "g" using control down'
sleep 0.5
osascript -e 'tell application "System Events" to keystroke "B275"'
osascript -e 'tell application "System Events" to key code 36'  # Enter
sleep 0.5

# Clear and paste (Escape + Delete + Cmd+V)
osascript -e 'tell application "System Events" to key code 53'  # Escape
osascript -e 'tell application "System Events" to key code 51'  # Delete
echo "New Value" | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
```

---

## Key Principles

1. **No New Windows**: Work with existing Chrome window only
2. **Dynamic Detection**: Find tabs by URL/title patterns, not hardcoded numbers
3. **Clipboard Method**: Use Cmd+A, Cmd+C for content that JS can't access
4. **Python Parsing**: Parse clipboard content with Python for structured data
5. **Validation**: Verify each step before proceeding to next
