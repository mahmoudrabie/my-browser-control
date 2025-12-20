# Validation

## Basic Connectivity

- [ ] Browser MCP extension installed in Chrome
- [ ] Extension shows in toolbar
- [ ] "Connect" button works in extension popup
- [ ] Status shows "Connected" after connecting to a tab

## MCP Client Setup

- [ ] MCP server configured in client settings
- [ ] Browser tools appear in tool list:
  - `browser_navigate`
  - `browser_snapshot`
  - `browser_click`
  - `browser_type`
  - `browser_wait`
  - `browser_screenshot`

## Functional Tests

### Test 1: Navigation
```
1. browser_navigate to https://example.com
2. browser_wait for 2 seconds
3. browser_snapshot
4. Verify: Page title is "Example Domain"
```

### Test 2: Page Interaction
```
1. browser_navigate to https://google.com
2. browser_wait for 2 seconds
3. browser_snapshot
4. Find search textbox ref
5. browser_type "test query" with submit: true
6. browser_wait for 2 seconds
7. browser_snapshot
8. Verify: Search results appear
```

### Test 3: ChatGPT Navigation (if applicable)
```
1. browser_navigate to https://chatgpt.com
2. browser_wait for 3 seconds
3. browser_snapshot
4. Verify: ChatGPT interface loads
5. Check sidebar shows projects/conversations
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "No tab with given id" | Reconnect via extension popup |
| Empty snapshot | Wait longer, page still loading |
| Stale refs | Take fresh snapshot before interaction |
| Tools not showing | Restart MCP client, check config |

## OS-Level Validation

If OS-level actions are required:
- [ ] Chrome has Accessibility permission
- [ ] MCP client app has Automation permission
- [ ] Can trigger system actions from browser context
