# Requirements

## Functional

- Scripts to automate LinkedIn post scheduling from ChatGPT content
- Scripts to extract LinkedIn post titles and update Google Sheets
- Scripts to clean content via Clean Paste website
- All scripts must start with Chrome window/tab inspection (mandatory first step)
- Dynamic tab detection by URL/title patterns (no hardcoded tab numbers)

## Core Automation Tools

| Tool | Purpose |
|------|---------|
| AppleScript | Chrome tab navigation, window control |
| System Events | Keyboard shortcuts (Cmd+A, Cmd+C, Cmd+V, etc.) |
| pbcopy/pbpaste | Clipboard management |
| Python | Content parsing, Unicode normalization, JSON processing |
| osascript | Execute AppleScript from bash |

## Key Functions

| Function | Purpose |
|----------|---------|
| `inspect_chrome_window()` | Verify window exists, get tab/window counts |
| `detect_required_tabs()` | Find tabs by URL pattern dynamically |
| `navigate_to_tab()` | Switch to tab by index |
| `copy_page_to_clipboard()` | Cmd+A, Cmd+C to capture page content |
| `normalize_title()` | Convert fancy Unicode to ASCII, strip emojis |

## Non-functional

- Local-only operations; no network calls outside browser
- Idempotent scripts; safe to rerun
- No new Chrome windows opened during automation
- Work with existing tabs in single Chrome window
- Clear error messages when required tabs missing
