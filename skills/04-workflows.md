# Workflow Skills

## Multi-Step Automation Patterns

### ChatGPT Project Navigation Workflow

**Goal:** Navigate to a specific conversation in a ChatGPT project

```yaml
# Step 1: Navigate to ChatGPT
Tool: browser_navigate
url: "https://chatgpt.com"

# Step 2: Wait for initial load
Tool: browser_wait
time: 3

# Step 3: Take snapshot to understand page
Tool: browser_snapshot

# Step 4: Find project in sidebar
# Look for: link "Project-Name" [ref=...]
# Extract the project URL

# Step 5: Navigate directly to project
Tool: browser_navigate
url: "https://chatgpt.com/g/g-p-{project-id}/project"

# Step 6: Wait and snapshot
Tool: browser_wait
time: 2
Tool: browser_snapshot

# Step 7: Find specific conversation
# Look for: link "Conversation Title" [ref=...]

# Step 8: Navigate to conversation
Tool: browser_navigate
url: "https://chatgpt.com/g/g-p-{project-id}/c/{conversation-id}"

# Step 9: Wait and snapshot to read content
Tool: browser_wait
time: 3
Tool: browser_snapshot
```

### Web Form Submission Workflow

**Goal:** Fill and submit a multi-field form

```yaml
# Step 1: Navigate to form page
Tool: browser_navigate
url: "https://example.com/form"

# Step 2: Wait and snapshot
Tool: browser_wait
time: 2
Tool: browser_snapshot

# Step 3: Fill each field (use refs from snapshot)
Tool: browser_type
element: "First Name field"
ref: "s2e10"
text: "John"
submit: false

Tool: browser_type
element: "Last Name field"
ref: "s2e11"
text: "Doe"
submit: false

Tool: browser_type
element: "Email field"
ref: "s2e12"
text: "john.doe@example.com"
submit: false

# Step 4: Select dropdown option
Tool: browser_select_option
element: "Country dropdown"
ref: "s2e15"
values: ["US"]

# Step 5: Check checkbox if needed
Tool: browser_click
element: "Terms checkbox"
ref: "s2e20"

# Step 6: Submit form
Tool: browser_click
element: "Submit button"
ref: "s2e30"

# Step 7: Verify success
Tool: browser_wait
time: 2
Tool: browser_snapshot
# Check for success message or redirect
```

### Search and Extract Workflow

**Goal:** Search a site and extract results

```yaml
# Step 1: Navigate to site
Tool: browser_navigate
url: "https://search-site.com"

# Step 2: Wait and snapshot
Tool: browser_wait
time: 2
Tool: browser_snapshot

# Step 3: Find search box
# Look for: textbox "Search" [ref=...]

# Step 4: Enter search query
Tool: browser_type
element: "Search box"
ref: "s2e50"
text: "search query"
submit: true

# Step 5: Wait for results
Tool: browser_wait
time: 3
Tool: browser_snapshot

# Step 6: Extract results from snapshot
# Parse article/list items for:
# - Titles
# - URLs
# - Descriptions

# Step 7: Optionally click a result
Tool: browser_click
element: "First result link"
ref: "s2e100"
```

### Login Workflow

**Goal:** Authenticate to a website

```yaml
# Step 1: Navigate to login page
Tool: browser_navigate
url: "https://example.com/login"

# Step 2: Wait and snapshot
Tool: browser_wait
time: 2
Tool: browser_snapshot

# Step 3: Enter credentials
Tool: browser_type
element: "Username/Email field"
ref: "s2e10"
text: "username"
submit: false

Tool: browser_type
element: "Password field"
ref: "s2e11"
text: "password"
submit: false

# Step 4: Click login button
Tool: browser_click
element: "Login/Sign In button"
ref: "s2e20"

# Step 5: Wait for redirect
Tool: browser_wait
time: 3
Tool: browser_snapshot

# Step 6: Verify login success
# Check for:
# - User menu/avatar
# - Dashboard content
# - Absence of login form
```

## Error Recovery Patterns

### Pattern: Retry on Failure

```yaml
# Attempt action
Tool: browser_click
element: "Target button"
ref: "s2e123"

# If error, refresh state
Tool: browser_snapshot

# Find element again (ref may have changed)
# Retry with new ref
Tool: browser_click
element: "Target button"
ref: "s2e456"  # Updated ref
```

### Pattern: Handle Loading States

```yaml
# Initial attempt
Tool: browser_snapshot

# If content shows loading:
#   - "Loading..." text
#   - Spinner elements
#   - Empty containers

# Wait and retry
Tool: browser_wait
time: 2
Tool: browser_snapshot

# Repeat until content appears or max retries
```

### Pattern: Navigate Back on Wrong Page

```yaml
# Check current state
Tool: browser_snapshot

# If unexpected page:
Tool: browser_go_back
# or
Tool: browser_navigate
url: "intended-url"

# Verify correct page
Tool: browser_wait
time: 2
Tool: browser_snapshot
```

## Best Practices for Workflows

1. **Always snapshot before interacting**
   - Refs are only valid for current page state
   - Page structure may have changed

2. **Use explicit waits**
   - After navigation
   - After clicking links
   - After form submissions
   - Before important snapshots

3. **Prefer direct navigation**
   - Use full URLs when known
   - More reliable than click chains
   - Avoids stale ref issues

4. **Handle dynamic content**
   - SPAs load content asynchronously
   - Wait for specific elements, not just time
   - Take multiple snapshots if needed

5. **Log progress**
   - Note successful steps
   - Record URLs visited
   - Save key refs for debugging

6. **Plan for failures**
   - Have fallback strategies
   - Don't assume elements exist
   - Verify page state after actions
