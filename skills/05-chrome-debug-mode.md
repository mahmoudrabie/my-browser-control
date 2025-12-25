# Chrome Browser Automation

## Two Approaches

### Approach 1: AppleScript (RECOMMENDED for existing profile)
**Use this when you need the user's logged-in profile with bookmarks**

```bash
# Open Chrome with existing profile and open tabs
osascript -e 'tell application "Google Chrome" to activate'
sleep 1
osascript -e 'tell application "Google Chrome" to if (count of windows) = 0 then make new window'
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "https://example.com"'
osascript -e 'tell application "Google Chrome" to tell front window to make new tab with properties {URL:"https://another.com"}'
```

**Pros:**
- ✅ Uses existing profile with logins and bookmarks
- ✅ No debug mode limitations
- ✅ Simple and reliable

**Cons:**
- ❌ Cannot switch/select tabs programmatically
- ❌ Limited interaction (can only open URLs, not click/type)

**Script available:** `scripts/open-browser-tabs.sh`

---

### Approach 2: CDP Debug Mode (for full control)
**Use this when you need full browser control (but fresh profile)**

```bash
# Start Chrome with debugging (requires separate data directory)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="/Users/mahmoudrabie/MyAIProjects/my-browser-control/datadir" \
  --no-first-run \
  --no-default-browser-check
```

**Pros:**
- ✅ Full control: click, type, switch tabs, screenshots
- ✅ Tab management with `list_pages`, `select_page`

**Cons:**
- ❌ Cannot use existing profile (Chrome security limitation)
- ❌ No logins or bookmarks

---

## Hybrid Workflow (Best of Both Worlds)

1. **Use AppleScript** to open Chrome with your profile and navigate to pages
2. **Then use Browser MCP** to interact with the active tab (click, type, etc.)

```bash
# Step 1: Open Chrome with profile using AppleScript
osascript -e 'tell application "Google Chrome" to activate'
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "https://cleanpaste.site"'

# Step 2: Connect Browser MCP extension to the tab
# Step 3: Use Browser MCP tools (browser_snapshot, browser_click, browser_type)
```

---

## Important Notes

- **Chrome Debug Mode CANNOT use existing profile** - this is a Google security feature
- **AppleScript can open URLs but not interact** - use Browser MCP for clicking/typing
- **Browser MCP needs extension connected** - click extension icon and "Connect" on target tab
