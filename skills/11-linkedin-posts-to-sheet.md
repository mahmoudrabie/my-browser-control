# LinkedIn Posts to Google Sheet Skill

## Description
Extract post titles from LinkedIn activity page and update Google Sheet based on discipline hashtags and dates.

## ⚠️ CRITICAL: Start with Window/Tab Inspection

**ALWAYS start by inspecting the opened Chrome window tabs** before any automation:
1. Verify Chrome has exactly 1 window open (no new windows will be created)
2. Dynamically detect tab numbers for LinkedIn Activity and Google Sheet
3. Only proceed if required tabs are found

## ⚠️ CRITICAL: Use Clipboard Method (Not JavaScript)

**JavaScript via AppleScript CANNOT access LinkedIn's dynamically loaded post content.** LinkedIn blocks access to DOM content through the `execute javascript` method.

**Proven working method:** Use `Cmd+A, Cmd+C` (Select All, Copy) to capture page content to clipboard, then parse with Python.

## Step 0: Inspect Opened Chrome Window Tabs (MANDATORY FIRST STEP)

### Verify Single Window & Count Tabs
```applescript
tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows open"
    set windowCount to count of windows
    set win to front window
    set tabCount to count of tabs of win
    return "Windows: " & windowCount & ", Tabs: " & tabCount
end tell
```

### Dynamically Find Required Tabs by URL Pattern
```applescript
tell application "Google Chrome"
    set win to front window
    set activityTab to 0
    set sheetTab to 0
    
    repeat with i from 1 to count of tabs of win
        set t to tab i of win
        set tabURL to URL of t
        set tabTitle to title of t
        
        -- Find LinkedIn Activity tab
        if tabURL contains "mahmoudrabie2004/recent-activity" then
            set activityTab to i
        end if
        
        -- Find Google Sheet tab by title
        if tabURL contains "docs.google.com/spreadsheets" then
            if tabTitle contains "Selected Sources" or tabTitle contains "Weekly posts" then
                set sheetTab to i
            end if
        end if
    end repeat
    
    return "Activity Tab: " & activityTab & ", Sheet Tab: " & sheetTab
end tell
```

### Bash Function for Tab Detection
```bash
# Detect tabs dynamically - returns "activity_tab:sheet_tab" or "error:message"
detect_required_tabs() {
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then return "error:No Chrome windows open"
    
    set win to front window
    set activityTab to 0
    set sheetTab to 0
    
    repeat with i from 1 to count of tabs of win
        set t to tab i of win
        set tabURL to URL of t
        set tabTitle to title of t
        
        if tabURL contains "mahmoudrabie2004/recent-activity" then
            set activityTab to i
        end if
        
        if tabURL contains "docs.google.com/spreadsheets" then
            if tabTitle contains "Selected Sources" or tabTitle contains "Weekly posts" then
                set sheetTab to i
            end if
        end if
    end repeat
    
    if activityTab = 0 then return "error:LinkedIn Activity tab not found"
    if sheetTab = 0 then return "error:Google Sheet tab not found"
    
    return (activityTab as string) & ":" & (sheetTab as string)
end tell
APPLESCRIPT
}
```

## Prerequisites
- Google Chrome with:
  - LinkedIn activity page open: `linkedin.com/in/mahmoudrabie2004/recent-activity/all/`
  - Google Sheet open: `My Selected Sources for Weekly posts`
  - **Tab numbers are detected dynamically** (no hardcoded values needed)

## Configuration (with Dynamic Tab Detection)
```bash
# Tabs are auto-detected, but can be overridden via environment variables
LINKEDIN_ACTIVITY_TAB="${LINKEDIN_ACTIVITY_TAB:-auto}"
GOOGLE_SHEET_TAB="${GOOGLE_SHEET_TAB:-auto}"
SHEET_START_DATE="2025-12-08"  # Row 237
SHEET_START_ROW=237
ROWS_PER_DATE=2  # Each date takes 2 rows in the sheet
```

## Hashtag to Discipline/Column Mapping
| Hashtag | Discipline | Column |
|---------|------------|--------|
| `#for_solutions_architects` | SOTA | B |
| `#for_ai_researchers` | Agentic AI | C |
| `#cyber_security_highlights` | Cybersecurity | D |
| `#open_source_ai_projects` | Open Source AI Projects | E |
| `#open_source_llms` | Open Source LLMs | F |

## Date/Time Handling
- Input format: `YYYY-MM-DD`
- LinkedIn displays relative time: `Xm`, `Xh`, `Xd`, `Xw`, `Xmo`
- Time markers appear in clipboard as: `4d •  4 days ago • Visible to...`
- Conversion: Same day = `Xm` or `Xh`, days ago = `Xd`

## Row Calculation (IMPORTANT: 2 rows per date)
```python
SHEET_START_DATE = "2025-12-08"
SHEET_START_ROW = 237
ROWS_PER_DATE = 2

def date_to_row(target_date):
    d1 = datetime.strptime(SHEET_START_DATE, '%Y-%m-%d')
    d2 = datetime.strptime(target_date, '%Y-%m-%d')
    days = (d2 - d1).days
    return SHEET_START_ROW + (days * ROWS_PER_DATE)

# Examples:
# Dec 22 = 237 + (14 * 2) = Row 265
# Dec 25 = 237 + (17 * 2) = Row 271
# Dec 26 = 237 + (18 * 2) = Row 273
```

## Title Normalization
Titles are cleaned before pasting:
1. **Unicode normalization**: Fancy text (`𝙎𝙚𝙘𝙪𝙧𝙞𝙣𝙜`) → plain ASCII (`Securing`)
2. **Emoji removal**: `🛡🤖 Title 🤖🛡` → `Title`

## Workflow Steps

### Step 1: Navigate to LinkedIn Activity Tab
```applescript
tell application "Google Chrome"
    activate
    set active tab index of front window to 7
end tell
```

### Step 2: Refresh and Scroll to Load Posts
```applescript
tell application "System Events"
    -- Refresh
    keystroke "r" using command down
    delay 2
    -- Scroll (Cmd+Down Arrow) to load more posts
    repeat 5 times
        key code 125 using command down
        delay 1
    end repeat
end tell
```

### Step 3: Copy Page Content (PROVEN METHOD)
```applescript
tell application "System Events"
    keystroke "a" using command down
    delay 0.5
    keystroke "c" using command down
    delay 0.5
end tell
```

### Step 4: Parse Clipboard with Python
Time pattern in clipboard: `^(\d+)(m|h|d|w|mo)\s*•`

```python
import re
time_line_pattern = re.compile(r'^(\d+)(m|h|d|w|mo)\s*•')

# Parse posts between time markers
# Extract title (first meaningful line after time marker)
# Find discipline from hashtags in post content
# Normalize title (remove fancy unicode + emojis)
```

### Step 5: Navigate to Google Sheet Tab
```applescript
tell application "Google Chrome"
    set active tab index of front window to 11
end tell
```

### Step 6: Update Cell (Clear + Paste)
```applescript
tell application "System Events"
    -- Go to cell with Ctrl+G
    keystroke "g" using control down
    delay 0.5
    keystroke "B265"  -- cell reference
    key code 36  -- Enter
    delay 0.5
    
    -- Clear cell first (Escape + Delete)
    key code 53  -- Escape (exit edit mode)
    delay 0.2
    key code 51  -- Delete (clear cell)
    delay 0.2
    
    -- Paste via clipboard
    keystroke "v" using command down
    delay 0.3
    key code 36  -- Enter to confirm
end tell
```

## Important Notes
- **JavaScript extraction DOES NOT WORK** - LinkedIn blocks access to dynamically loaded content
- **AppleScript UI scripting DOES NOT WORK** - Chrome doesn't expose web content via accessibility APIs
- **MUST use Escape+Delete** before pasting to clear existing cell content (prevents appending)
- Each date occupies **2 rows** in the Google Sheet
- Scroll LinkedIn page to load posts in your date range (~3 posts per scroll)
- Posts are ordered newest first

## Script Usage
```bash
# Basic usage
./scripts/17-linkedin-posts-to-sheet.sh START_DATE END_DATE

# Examples
./scripts/17-linkedin-posts-to-sheet.sh 2025-12-22 2025-12-26
./scripts/17-linkedin-posts-to-sheet.sh 2025-12-01 2025-12-31

# Override tab numbers
LINKEDIN_ACTIVITY_TAB=7 GOOGLE_SHEET_TAB=11 ./scripts/17-linkedin-posts-to-sheet.sh 2025-12-22 2025-12-26
```

## Tested Results (Dec 26, 2025)
Successfully extracted and updated:
- Dec 22: 5 posts (B, C, D, E, F columns)
- Dec 25: 1 post (E column)
- Dec 26: 3 posts (B, C, F columns)
