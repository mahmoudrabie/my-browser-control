# Browser MCP Skills

This directory contains reusable skill patterns for Browser MCP automation.

## Skills Index

| Skill | Description | File |
|-------|-------------|------|
| Navigation | Page navigation, URL handling, waiting | [01-navigation.md](01-navigation.md) |
| Interaction | Clicking, typing, form filling | [02-interaction.md](02-interaction.md) |
| Page Analysis | Snapshots, element discovery | [03-page-analysis.md](03-page-analysis.md) |
| Workflows | Multi-step automation patterns | [04-workflows.md](04-workflows.md) |

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
