# Steps

## Pre-requisites

1. Google Chrome installed and running
2. Single Chrome window with required tabs open
3. macOS Accessibility permissions granted to Terminal/VS Code
4. Logged into LinkedIn, Google Sheets, ChatGPT

## Workflow 1: LinkedIn Posts to Google Sheet

### Script: `scripts/17-linkedin-posts-to-sheet.sh`

**Usage:**
```bash
./scripts/17-linkedin-posts-to-sheet.sh 2025-12-27 2025-12-27
```

**Steps:**
0. **Inspect Chrome Window** (mandatory first step)
   - Verify single window exists
   - Auto-detect LinkedIn Activity tab and Google Sheet tab
1. Navigate to LinkedIn Activity tab
2. Refresh page (Cmd+R)
3. Scroll to load posts (Cmd+Down)
4. Copy page content (Cmd+A, Cmd+C)
5. Parse clipboard with Python (extract titles, dates, disciplines)
6. Navigate to Google Sheet tab
7. For each post: Go to cell (Ctrl+G), clear (Esc+Delete), paste (Cmd+V)

## Workflow 2: ChatGPT to LinkedIn Scheduler (19-Step)

### Script: `scripts/16-chatgpt-to-linkedin-scheduler.sh`

**Usage:**
```bash
./scripts/16-chatgpt-to-linkedin-scheduler.sh
```

**Steps:**
0. **Inspect Chrome Window** (mandatory first step)
   - Verify: ChatGPT, CleanPaste, LinkedIn, GoogleSheet tabs exist

**ChatGPT Phase (Steps 1-4):**
1. Clear clipboard
2. Navigate to ChatGPT tab by GPT ID
3. Scroll to bottom (Cmd+End)
4. Extract text from DOM → clipboard

**Clean Paste Phase (Steps 5-10):**
5. Navigate to Clean Paste tab
6. Refresh page (Cmd+R)
7. Focus textarea and paste (Cmd+V)
8. Click "Clean Text" button
9. Close modal if present
10. Extract cleaned text → clipboard

**LinkedIn Phase (Steps 11-14):**
11. Navigate to LinkedIn tab
12. Scroll to top (Cmd+Home)
13. Click "Start a post" button
14. Focus editor and paste (Cmd+V)

**Scheduling Phase (Steps 15-19):**
15. Click clock icon (Schedule post)
16. Set date
17. Set time
18. Click "Next"
19. Click "Schedule"

## Skills Reference

See `skills/` directory for detailed patterns:
- [08-chrome-tab-navigator.md](../skills/08-chrome-tab-navigator.md) - Window inspection, tab detection
- [09-google-sheets-updater.md](../skills/09-google-sheets-updater.md) - Sheet cell updates
- [10-linkedin-post-scheduler.md](../skills/10-linkedin-post-scheduler.md) - 19-step workflow
- [11-linkedin-posts-to-sheet.md](../skills/11-linkedin-posts-to-sheet.md) - Activity extraction
