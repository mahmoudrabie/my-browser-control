# Browser Automation Comparison

## Available Methods

| Feature | **AppleScript** | **Browser MCP** | **Chrome DevTools MCP** | **Playwright MCP** |
|---------|-----------------|-----------------|-------------------------|---------------------|
| **Uses Your Profile** | ✅ Yes | ✅ Yes | ❌ No (fresh profile) | ❌ No (isolated) |
| **List/Switch Tabs** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Navigate** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Click** | ✅ Yes (via JS) | ✅ Yes | ✅ Yes | ✅ Yes |
| **Type Text** | ✅ Yes (via JS) | ✅ Yes | ✅ Yes | ✅ Yes |
| **Read Content** | ✅ Yes (via JS) | ✅ Yes | ✅ Yes | ✅ Yes |
| **Take Screenshot** | ❌ No | ❌ No | ✅ Yes | ✅ Yes |
| **No Extension Needed** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Setup Required** | Enable JS once | Install extension | Start with flags | None |
| **Stability** | ✅ Stable | ⚠️ Timeouts | ✅ Stable | ✅ Stable |

---

## Recommendation

### 🏆 **AppleScript is the BEST option** for:
- Using your existing Chrome profile with logins/bookmarks
- Full automation (open tabs, switch tabs, click, type, read)
- No extensions or special browser flags needed
- One-time setup only

### Use Browser MCP when:
- You need the accessibility tree snapshot
- AppleScript JS execution is disabled

### Use Chrome DevTools MCP when:
- You need screenshots or performance tracing
- You don't need your logged-in profile
- You need advanced debugging features

### Use Playwright MCP when:
- You want zero-setup automation
- You don't need your logged-in profile
- You want to run custom Playwright code

---

## Setup Instructions

### Browser MCP
1. Install the Browser MCP Chrome extension
2. Click the extension icon and "Connect" on the tab you want to control
3. MCP connects to that single tab

### Chrome DevTools MCP
```bash
# Start Chrome with debugging (requires separate data directory)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="/path/to/custom/datadir" \
  --no-first-run \
  --no-default-browser-check
```

### Playwright MCP
- No setup needed - automatically launches its own browser instance
- Cannot connect to existing Chrome

---

## Key Tools Reference

### Chrome DevTools MCP (Best for Full Control)
- `list_pages` - List all open tabs
- `select_page` - Switch to a specific tab
- `new_page` - Open new tab
- `navigate_page` - Navigate current tab
- `take_snapshot` - Get page accessibility tree
- `click` - Click element by uid
- `fill` - Type into input
- `fill_form` - Fill multiple form fields
- `evaluate_script` - Run JavaScript
- `take_screenshot` - Capture page image
- `performance_start_trace` - Start performance recording

### Browser MCP (Best for Profile Access)
- `browser_snapshot` - Get page accessibility tree
- `browser_click` - Click element by ref
- `browser_type` - Type into element
- `browser_navigate` - Navigate to URL
- `browser_press_key` - Send keyboard input

### Playwright MCP (Best for No-Setup Automation)
- `browser_tabs` - List/create/close/select tabs
- `browser_navigate` - Navigate to URL
- `browser_snapshot` - Get page accessibility tree
- `browser_click` - Click element
- `browser_type` - Type text
- `browser_run_code` - Execute custom Playwright code
