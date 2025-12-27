# Chrome Tab Navigator Skill

## Description
Navigate between Chrome tabs by URL pattern or title. **Always start by inspecting opened window tabs.**

## ⚠️ CRITICAL: Start with Window Inspection (MANDATORY FIRST STEP)

Before any automation, verify Chrome window state and detect tabs dynamically:

### Verify Chrome Window Exists
```applescript
tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows open"
    set windowCount to count of windows
    set win to front window
    set tabCount to count of tabs of win
    set activeIdx to active tab index of win
    return "Windows: " & windowCount & ", Tabs: " & tabCount & ", Active: Tab " & activeIdx
end tell
```

### Bash Function: Inspect Chrome Window
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

## Find and Activate Tab by URL Pattern

```applescript
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "linkedin.com" then
                set active tab index of w to tabIndex
                set index of w to 1
                activate
                return "Activated tab"
            end if
            set tabIndex to tabIndex + 1
        end repeat
    end repeat
    return "Tab not found"
end tell
```

## List All Open Tabs

```applescript
tell application "Google Chrome"
    set tabList to ""
    repeat with w in windows
        repeat with t in tabs of w
            set tabList to tabList & title of t & " | " & URL of t & linefeed
        end repeat
    end repeat
    return tabList
end tell
```

## Common URL Patterns

| Site | URL Pattern |
|------|-------------|
| LinkedIn Feed | `linkedin.com/feed` |
| Google Sheets | `docs.google.com/spreadsheets` |
| ChatGPT | `chatgpt.com` |
| Clean Paste | `cleanpaste.site` |

## ChatGPT Tab Identifiers (GPT IDs)
- SOTA-Posts: `689731221e7881919f3f0b3b80f70f6b`
- Agentic-AI-Search: `687b4667bb988191ac0aa4a96358607f`
- cyber-security-highlights: `6895b9c4ec188191a8322d5955fc76ef`
- open-source-AI-Projects: `689f374e6008819182ed6cb8d6d93826`
- open-source-llms: `68a26a3f484c8191b33389a508d57685`
