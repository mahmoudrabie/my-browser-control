# Page Analysis Skills

## Accessibility Snapshots

### Take Snapshot
```
Tool: mcp_browsermcp_browser_snapshot
Parameters: (none required)
```

**Returns:**
- Page URL
- Page Title
- YAML-structured accessibility tree with element refs

### Understanding Snapshot Output

```yaml
- Page URL: https://example.com
- Page Title: Example Page
- Page Snapshot:
  - document [ref=s2e1]:
    - banner [ref=s2e10]:
      - link "Home" [ref=s2e11]:
        - /url: /
      - navigation [ref=s2e15]:
        - link "About" [ref=s2e16]:
          - /url: /about
    - main [ref=s2e20]:
      - heading "Welcome" [level=1] [ref=s2e21]
      - paragraph [ref=s2e22]: Some text content
      - button "Click Me" [ref=s2e30]
      - textbox "Email" [ref=s2e40]
```

### Key Element Types

| Type | Description | Interactions |
|------|-------------|--------------|
| `link` | Hyperlinks | click, read URL |
| `button` | Clickable buttons | click |
| `textbox` | Text input fields | type |
| `checkbox` | Toggle checkboxes | click |
| `combobox` | Dropdowns | select_option |
| `heading` | Section headings | read content |
| `paragraph` | Text content | read content |
| `article` | Content sections | read/navigate |
| `navigation` | Nav containers | find links |

### Element Attributes

- `[ref=s2eXXX]` - Unique reference for interactions
- `[level=N]` - Heading level (1-6)
- `[expanded]` - Expandable element state
- `[disabled]` - Non-interactive state
- `/url: ...` - Link destination

## Visual Screenshots

### Capture Screenshot
```
Tool: mcp_browsermcp_browser_screenshot
Parameters: (none required)
```

**Use cases:**
- Visual verification
- Debugging layout issues
- Capturing visual content (images, charts)
- Documenting page states

## Page Analysis Patterns

### Pattern: Find Specific Element

```yaml
# 1. Take snapshot
Tool: browser_snapshot

# 2. Search output for element by:
#    - Text content: "Submit", "Login"
#    - Element type: button, link, textbox
#    - Nearby elements/context

# 3. Extract ref value for interaction
# Example: button "Submit" [ref=s2e123]
#          -> use ref="s2e123"
```

### Pattern: Understand Page Structure

```yaml
# 1. Take snapshot
Tool: browser_snapshot

# 2. Identify major sections:
#    - banner/header
#    - navigation
#    - main content
#    - complementary (sidebars)
#    - contentinfo (footer)

# 3. Map out available actions based on:
#    - Links (navigation options)
#    - Buttons (actions)
#    - Forms (data input)
```

### Pattern: Verify Page Content

```yaml
# 1. Navigate to expected page
Tool: browser_navigate
url: "https://example.com/expected-page"

# 2. Wait for load
Tool: browser_wait
time: 2

# 3. Snapshot and verify
Tool: browser_snapshot

# 4. Check in output:
#    - Page title matches expected
#    - Key headings present
#    - Expected elements visible
```

### Pattern: Monitor Dynamic Content

```yaml
# Initial snapshot
Tool: browser_snapshot

# Trigger action that changes content
Tool: browser_click
element: "Load More button"
ref: "s2e100"

# Wait for update
Tool: browser_wait
time: 2

# New snapshot to see changes
Tool: browser_snapshot

# Compare before/after to verify changes
```

## Reading Long Pages

### Strategy: Scroll and Snapshot

For pages longer than viewport:
1. Take initial snapshot (top of page)
2. Note what's visible
3. Click "scroll" element or use keyboard
4. Take another snapshot
5. Repeat until content found

### Strategy: Use Page Search

If available, use the page's search:
1. Find search input in snapshot
2. Type search query
3. Wait for results
4. Snapshot to find highlighted/matched content

## ChatGPT-Specific Patterns

### Reading Conversation History

```yaml
# ChatGPT shows articles for each message
# Structure:
# - article [ref=...]:
#   - heading "You said:" [ref=...]
#   - text: "User message content"
# - article [ref=...]:
#   - heading "ChatGPT said:" [ref=...]
#   - paragraph: "Response content"
```

### Finding Projects and Conversations

```yaml
# Sidebar contains:
# - link "Project Name" [ref=...]:
#   - /url: /g/g-p-{id}/project
# - link "Conversation Title" [ref=...]:
#   - /url: /g/g-p-{id}/c/{conv-id}
```

## Common Issues

### Issue: Truncated Snapshot
**Symptom:** Important content missing from output
**Solutions:**
- Page may need scrolling
- Content may be lazy-loaded (wait longer)
- Take multiple snapshots at different scroll positions

### Issue: Dynamic Refs
**Symptom:** Refs change between snapshots
**Solutions:**
- Always use refs from the most recent snapshot
- Re-snapshot before any interaction
- Don't cache refs across navigation
