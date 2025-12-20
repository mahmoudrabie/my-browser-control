# Navigation Skills

## Basic Navigation

### Navigate to URL
```
Tool: mcp_browsermcp_browser_navigate
Parameters:
  url: "https://example.com"
```

**Notes:**
- Always use full URLs including protocol (https://)
- Wait after navigation for page to load
- Check page title in snapshot to confirm correct page

### Wait for Page Load
```
Tool: mcp_browsermcp_browser_wait
Parameters:
  time: 3  # seconds
```

**When to use:**
- After navigation to dynamic pages (SPAs)
- After clicking links that trigger client-side routing
- Before taking snapshots on slow-loading pages

## Navigation Patterns

### Pattern: Direct URL vs Click Navigation

**Prefer Direct URL when:**
- You know the destination URL
- The page uses client-side routing (React, Vue, etc.)
- Clicking causes stale element references

**Use Click Navigation when:**
- URL is unknown or dynamically generated
- You need to trigger JavaScript events
- Testing user flow behavior

### Pattern: ChatGPT Project Navigation

```yaml
# Step 1: Navigate to ChatGPT
Tool: browser_navigate
url: "https://chatgpt.com"

# Step 2: Wait for load
Tool: browser_wait
time: 3

# Step 3: Snapshot to find elements
Tool: browser_snapshot

# Step 4: Navigate directly to project/conversation URL
Tool: browser_navigate
url: "https://chatgpt.com/g/g-p-{project-id}/project"
```

### Pattern: Handling Dynamic Pages

For SPAs (Single Page Applications) like ChatGPT:
1. Navigate to the base URL
2. Wait for initial load (2-3 seconds)
3. Take snapshot to understand page structure
4. Navigate directly to sub-pages using full URLs
5. Wait again after navigation
6. Take fresh snapshot

## Common Issues

### Issue: Stale Tab References
**Symptom:** "No tab with given id" errors after navigation
**Solution:** After major navigations, take a new snapshot before interacting

### Issue: Content Not Loaded
**Symptom:** Snapshot shows loading states or empty content
**Solution:** Increase wait time, or wait for specific elements

### Issue: Wrong Page
**Symptom:** Snapshot shows unexpected content
**Solution:** Verify URL format, check for redirects, handle login flows
