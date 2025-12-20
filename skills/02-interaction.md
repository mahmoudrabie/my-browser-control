# Interaction Skills

## Click Operations

### Basic Click
```
Tool: mcp_browsermcp_browser_click
Parameters:
  element: "Human-readable description of element"
  ref: "s2e123"  # Reference from snapshot
```

**Important:**
- Always get element `ref` from a recent snapshot
- Use descriptive `element` parameter for clarity
- Refs become stale after page changes

### Example: Clicking a Button
```yaml
# Step 1: Get current page state
Tool: browser_snapshot

# Step 2: Find button in snapshot output
# Example: button "Submit" [ref=s2e45]

# Step 3: Click the button
Tool: browser_click
element: "Submit button"
ref: "s2e45"
```

## Text Input

### Type into Field
```
Tool: mcp_browsermcp_browser_type
Parameters:
  element: "Description of input field"
  ref: "s2e67"
  text: "Text to type"
  submit: false  # Set true to press Enter after
```

### Example: Search Query
```yaml
# Type search query and submit
Tool: browser_type
element: "Search input field"
ref: "s2e89"
text: "your search query"
submit: true
```

### Example: Form Filling
```yaml
# Fill username (don't submit)
Tool: browser_type
element: "Username field"
ref: "s2e12"
text: "myusername"
submit: false

# Fill password and submit
Tool: browser_type
element: "Password field"
ref: "s2e34"
text: "mypassword"
submit: true
```

## Dropdown Selection

### Select Option
```
Tool: mcp_browsermcp_browser_select_option
Parameters:
  element: "Description of dropdown"
  ref: "s2e90"
  values: ["option_value"]
```

## Hover Operations

### Hover Over Element
```
Tool: mcp_browsermcp_browser_hover
Parameters:
  element: "Element to hover over"
  ref: "s2e100"
```

**Use cases:**
- Reveal hidden menus
- Trigger tooltips
- Activate hover states before clicking

## Keyboard Operations

### Press Key
```
Tool: mcp_browsermcp_browser_press_key
Parameters:
  key: "Enter"  # or "ArrowDown", "Escape", "Tab", etc.
```

**Common keys:**
- `Enter` - Submit forms, confirm actions
- `Escape` - Close modals, cancel operations
- `Tab` - Move focus between elements
- `ArrowUp`, `ArrowDown` - Navigate lists
- `Backspace` - Delete text

## Interaction Patterns

### Pattern: Navigate Sidebar Menu
```yaml
# 1. Snapshot to find sidebar items
Tool: browser_snapshot

# 2. Identify menu item from snapshot
# Example: link "Settings" [ref=s2e156]

# 3. Click the menu item
Tool: browser_click
element: "Settings menu item"
ref: "s2e156"

# 4. Wait for content to load
Tool: browser_wait
time: 2

# 5. Take new snapshot
Tool: browser_snapshot
```

### Pattern: Fill and Submit Form
```yaml
# 1. Snapshot to find form fields
Tool: browser_snapshot

# 2. Fill each field
Tool: browser_type
element: "Name field"
ref: "s2e20"
text: "John Doe"
submit: false

Tool: browser_type
element: "Email field"
ref: "s2e21"
text: "john@example.com"
submit: false

# 3. Click submit button
Tool: browser_click
element: "Submit button"
ref: "s2e30"
```

## Common Issues

### Issue: Element Not Interactable
**Symptom:** Click or type has no effect
**Solutions:**
- Wait for element to become visible
- Scroll element into view first
- Check if element is behind a modal/overlay

### Issue: Wrong Element Clicked
**Symptom:** Unexpected behavior after click
**Solutions:**
- Verify ref matches intended element in snapshot
- Use more specific element descriptions
- Check for duplicate elements on page
