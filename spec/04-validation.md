# Validation

## Pre-flight Checks

- [ ] Chrome is running with single window
- [ ] Required tabs are open (varies by workflow)
- [ ] macOS Accessibility permissions granted
- [ ] Logged into required services (LinkedIn, Google, ChatGPT)

## Window Inspection Validation

Run this to verify Chrome setup:
```bash
osascript -e '
tell application "Google Chrome"
    if (count of windows) = 0 then return "error:No Chrome windows"
    set win to front window
    return "ok:" & (count of windows) & ":" & (count of tabs of win)
end tell
'
```

Expected: `ok:1:N` (1 window, N tabs)

## Workflow 1: LinkedIn Posts to Sheet

### Test Command
```bash
./scripts/17-linkedin-posts-to-sheet.sh 2025-12-27 2025-12-27
```

### Expected Output
```
Step 0: Inspecting opened Chrome window...
  Chrome windows: 1, Front window tabs: N, Active: Tab X
  Auto-detecting required tabs...
  LinkedIn Activity Tab: Y
  Google Sheet Tab: Z

Step 1: Navigate to LinkedIn activity tab (Y)
...
Found N posts in date range
...
Workflow complete!
```

### Validation Points
- [ ] Window inspection succeeds (Step 0)
- [ ] Tab detection finds both LinkedIn Activity and Google Sheet
- [ ] Posts are extracted with correct dates
- [ ] Titles are normalized (no fancy Unicode, no emojis)
- [ ] Sheet cells are updated correctly

## Workflow 2: ChatGPT to LinkedIn Scheduler

### Test Command
```bash
./scripts/16-chatgpt-to-linkedin-scheduler.sh
```

### Expected Output
```
Step 0: Inspecting opened Chrome window...
  ✅ Chrome windows: 1
  ✅ Front window tabs: N
  ✅ Active tab: #X
  
  Checking for required tabs...
  ✅ All required tabs found:
    - ChatGPT ✓
    - CleanPaste ✓
    - LinkedIn ✓
    - GoogleSheet ✓
```

### Validation Points
- [ ] Window inspection succeeds
- [ ] All 4 required tabs detected (ChatGPT, CleanPaste, LinkedIn, GoogleSheet)
- [ ] Content copied from ChatGPT (100+ chars)
- [ ] Content cleaned via CleanPaste
- [ ] Post created on LinkedIn
- [ ] Schedule dialog completed

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "No Chrome windows open" | Chrome not running | Open Chrome with tabs |
| "LinkedIn Activity tab not found" | Tab not open or different URL | Open `linkedin.com/in/USER/recent-activity/all/` |
| "Google Sheet tab not found" | Tab not open or wrong sheet | Open "My Selected Sources" sheet |
| "0 posts found" | Not scrolled enough or date range | Increase scroll count |
| Clipboard empty after Cmd+A,C | Page not focused | Click page first, retry |
| Cell not updated | Wrong cell reference | Verify row calculation |

## Tab Detection Patterns

| Tab | URL Pattern | Title Pattern |
|-----|-------------|---------------|
| LinkedIn Activity | `mahmoudrabie2004/recent-activity` | - |
| Google Sheet | `docs.google.com/spreadsheets` | "Selected Sources" or "Weekly posts" |
| ChatGPT | `chatgpt.com` | - |
| Clean Paste | `cleanpaste` | - |
| LinkedIn Feed | `linkedin.com/feed` or `linkedin.com/in/` | - |
