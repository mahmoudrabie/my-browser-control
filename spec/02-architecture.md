# Architecture

## Components

- **Google Chrome** - Single window with all required tabs open
- **AppleScript** - Chrome control, tab navigation, window inspection
- **System Events** - Keyboard shortcuts, UI automation
- **Bash Scripts** - Workflow orchestration
- **Python** - Content parsing, normalization, data transformation

## Control Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Bash Script (Orchestrator)               │
│                                                             │
│  ┌─────────────────┐   ┌─────────────────┐                 │
│  │ Step 0: Inspect │   │ Step N: Execute │                 │
│  │ Chrome Window   │ → │ Automation      │                 │
│  └────────┬────────┘   └────────┬────────┘                 │
│           │                     │                          │
│           ▼                     ▼                          │
│  ┌─────────────────┐   ┌─────────────────┐                 │
│  │   AppleScript   │   │  System Events  │                 │
│  │ (osascript)     │   │ (keyboard/UI)   │                 │
│  └────────┬────────┘   └────────┬────────┘                 │
│           │                     │                          │
│           └──────────┬──────────┘                          │
│                      ▼                                     │
│              ┌──────────────┐                              │
│              │ Google Chrome│                              │
│              │ (1 window,   │                              │
│              │  N tabs)     │                              │
│              └──────────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

## Tab Structure (Typical Setup)

| Tab | Content | URL Pattern |
|-----|---------|-------------|
| 1-5 | ChatGPT GPTs | `chatgpt.com/g/` |
| 6 | Clean Paste | `cleanpaste.site` |
| 7 | LinkedIn Feed | `linkedin.com/feed` |
| 8 | LinkedIn Activity | `linkedin.com/in/*/recent-activity` |
| 9 | Google Sheet | `docs.google.com/spreadsheets` |

**Note**: Tab numbers are detected dynamically, not hardcoded.

## Key Constraints

1. **Single Window**: All automation works within one Chrome window
2. **No New Windows**: Scripts never create new browser windows
3. **Dynamic Detection**: Tab positions detected by URL/title patterns
4. **Clipboard Method**: Use Cmd+A/Cmd+C for content (JavaScript blocked)
5. **Window Inspection First**: Every workflow starts with `init_chrome_window()`

## Data Flow Example: LinkedIn Posts to Sheet

```
LinkedIn Activity Tab
        │
        │ Cmd+A, Cmd+C
        ▼
    Clipboard (pbpaste)
        │
        │ Python parsing
        ▼
    Posts JSON [{title, date, discipline, column}]
        │
        │ For each post
        ▼
    Google Sheet Tab
        │
        │ Ctrl+G → Cell, Escape, Delete, Cmd+V
        ▼
    Updated Sheet
```
