# AppleScript Chrome Automation Guide

## Overview

The `applescript-full-automation.sh` script provides a production-ready framework for automating Chrome browser interactions using AppleScript and JavaScript. It demonstrates advanced patterns for browser automation without requiring browser extensions.

## Features

### ✅ Core Capabilities

- **Tab Management**: List, find, switch, and create tabs
- **Navigation**: Navigate to URLs with load verification
- **Form Interaction**: Fill textareas/inputs with proper event dispatching
- **Text Extraction**: Multiple fallback strategies for reading page content
- **Error Handling**: Comprehensive error checking and user feedback
- **Safe Text Handling**: Base64 encoding for special characters and multi-byte text
- **Logging**: Timestamped logs with success/error indicators
- **Clipboard Integration**: Auto-copy results for easy access

### 🎯 Use Cases

1. **Web form automation** - Fill and submit forms programmatically
2. **Data extraction** - Scrape and process web page content
3. **Multi-page workflows** - Coordinate actions across multiple tabs
4. **Text processing** - Send text to web tools and retrieve results
5. **Testing** - Automated browser testing with your actual profile

## Prerequisites

### One-Time Setup

1. **Enable JavaScript from Apple Events in Chrome**
   - Open Chrome
   - Menu: **View → Developer → Allow JavaScript from Apple Events**
   - This setting persists across Chrome restarts

2. **Grant macOS Automation Permissions** (when prompted)
   - System will ask for Automation permission for Terminal/iTerm
   - Go to: System Settings → Privacy & Security → Automation
   - Enable permissions for your terminal app to control Chrome

## Usage

### Basic Usage

```bash
# Use default URL and text
./applescript-full-automation.sh

# Custom URL
./applescript-full-automation.sh "https://example.com"

# Custom URL and text
./applescript-full-automation.sh "https://cleanpaste.site" "My text to clean"
```

### Help

```bash
./applescript-full-automation.sh --help
```

### Environment Variables

Create a `.env` file in the project root:

```bash
# Default URL for automation
DEFAULT_URL="https://cleanpaste.site"

# Default text to process
DEFAULT_TEXT="Your default text here"
```

## Script Architecture

### Main Functions

#### 1. Chrome Status & Management

```bash
chrome_check_running()      # Verify Chrome is running and has windows
chrome_list_tabs()          # Get list of all open tabs
chrome_get_page_info()      # Get current page title, URL, ready state
```

#### 2. Navigation & Tab Control

```bash
chrome_navigate_to()        # Navigate to URL and wait for load
chrome_switch_to_tab()      # Find and activate tab by URL/title hint
```

#### 3. Interaction

```bash
chrome_fill_and_submit()    # Fill form fields and click submit button
chrome_extract_text()       # Extract text with multiple fallback strategies
```

#### 4. Utilities

```bash
b64_encode()               # Base64 encode text for safe transmission
b64_decode()               # Base64 decode text from AppleScript
validate_json()            # Validate JSON responses from JavaScript
log()                      # Timestamped logging
log_success()              # Success message logging
log_error()                # Error message logging
```

## Advanced Patterns

### Pattern 1: Multi-Tab Workflow

```bash
# Switch to existing tab or create new one
chrome_switch_to_tab "linkedin.com" || chrome_navigate_to "https://linkedin.com"

# Perform action
chrome_fill_and_submit "$text_b64" "post"

# Switch to another tab
chrome_switch_to_tab "twitter.com"
```

### Pattern 2: Text Processing Pipeline

```bash
# Extract from source
text=$(chrome_extract_text | jq -r '.text')

# Process
processed=$(echo "$text" | your_processing_command)

# Send to destination
echo "$processed" | b64_encode | xargs -I {} chrome_fill_and_submit {} "submit"
```

### Pattern 3: Robust Element Interaction

The script uses multiple strategies to find and interact with elements:

```javascript
// Try multiple selectors
const element = 
  document.querySelector('textarea') ||
  document.querySelector('input[type="text"]') ||
  document.querySelector('[contenteditable="true"]');

// Dispatch proper events for React/Vue compatibility
element.value = text;
element.dispatchEvent(new Event('input', { bubbles: true }));
element.dispatchEvent(new Event('change', { bubbles: true }));
```

### Pattern 4: Error Recovery

```bash
# Try primary method
if ! chrome_navigate_to "$URL" 3; then
    log_error "Navigation failed, trying fallback..."
    # Fallback strategy
    chrome_switch_to_tab "$URL_HINT" || exit 1
fi
```

## JavaScript Execution from AppleScript

### Basic Pattern

```applescript
tell application "Google Chrome"
    set result to execute front window's active tab javascript "
        // Your JavaScript code here
        return someValue;
    "
end tell
```

### Best Practices

1. **Return JSON strings** for complex data:
   ```javascript
   return JSON.stringify({ ok: true, data: myData });
   ```

2. **Handle errors gracefully**:
   ```javascript
   try {
       // Your code
       return JSON.stringify({ ok: true });
   } catch (err) {
       return JSON.stringify({ ok: false, error: err.message });
   }
   ```

3. **Dispatch events for frameworks**:
   ```javascript
   element.dispatchEvent(new Event('input', { bubbles: true }));
   ```

4. **Use base64 for special characters**:
   ```javascript
   const bytes = Uint8Array.from(atob(base64Text), c => c.charCodeAt(0));
   const text = new TextDecoder('utf-8').decode(bytes);
   ```

## Text Extraction Strategies

The `chrome_extract_text()` function tries multiple methods in order:

1. **Output textarea** (second textarea on page) - Common for tools with input/output
2. **Single textarea** - Simple forms
3. **Pre/code blocks** - Formatted output
4. **Contenteditable elements** - Rich text editors
5. **Output divs** - Elements with class/id containing "output" or "result"
6. **Body text** - Fallback to full page text

This ensures maximum compatibility across different page structures.

## Comparison with Other Approaches

| Feature | AppleScript | Puppeteer/Playwright | Selenium | Browser MCP |
|---------|-------------|----------------------|----------|-------------|
| Uses your profile | ✅ Yes | ⚠️ Requires setup | ⚠️ Requires setup | ✅ Yes |
| Extensions available | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| Logged-in sessions | ✅ Yes | ⚠️ Manual | ⚠️ Manual | ✅ Yes |
| Tab switching | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Limited |
| Setup complexity | ⭐ Simple | ⭐⭐⭐ Complex | ⭐⭐⭐ Complex | ⭐⭐ Medium |
| macOS only | ⚠️ Yes | ✅ Cross-platform | ✅ Cross-platform | ✅ Cross-platform |
| Requires extension | ❌ No | ❌ No | ❌ No | ✅ Yes |

**AppleScript is ideal for macOS users who want simple automation with their existing Chrome profile and extensions.**

## Troubleshooting

### "Chrome is not running"
- Start Chrome and ensure at least one window is open
- The script cannot launch Chrome automatically (by design)

### "Allow JavaScript from Apple Events" not enabled
- Go to Chrome menu: View → Developer → Allow JavaScript from Apple Events
- Check mark should appear next to the menu item

### "No tab found matching: [URL]"
- Ensure a tab with that URL is actually open
- Try partial matches (e.g., "example" instead of "https://example.com")
- Use `chrome_list_tabs()` to see available tabs

### "Operation not permitted"
- Grant Automation permission in System Settings
- Path: System Settings → Privacy & Security → Automation
- Enable permissions for Terminal/iTerm to control Chrome

### Form not filling correctly
- Increase delay after navigation: `chrome_navigate_to "$URL" 5`
- Check if page uses shadow DOM (may require different selectors)
- Verify textarea/input is not inside an iframe

### Extracted text is empty
- Check if content is dynamically loaded (increase wait time)
- Verify extraction method in logs
- Content might be in shadow DOM or iframe (requires different approach)

## Examples

### Example 1: Clean Paste Workflow

```bash
#!/usr/bin/env bash
TEXT="Text with   extra   spaces and formatting"
./applescript-full-automation.sh "https://cleanpaste.site" "$TEXT"
```

### Example 2: Multi-Site Cross-Posting

```bash
#!/usr/bin/env bash
# Extract from one site, post to another

# Get content from source
SOURCE_TEXT=$(./applescript-full-automation.sh "https://source-site.com" "" | tail -1)

# Post to destination
./applescript-full-automation.sh "https://destination-site.com" "$SOURCE_TEXT"
```

### Example 3: Batch Processing

```bash
#!/usr/bin/env bash
# Process multiple texts

while IFS= read -r line; do
    echo "Processing: $line"
    ./applescript-full-automation.sh "https://cleanpaste.site" "$line"
done < input.txt
```

### Example 4: Integration with Other Tools

```bash
#!/usr/bin/env bash
# Combine with jq for JSON processing

RESULT=$(./applescript-full-automation.sh "$URL" "$TEXT" 2>/dev/null)
echo "$RESULT" | jq -r '.processed_text' > output.txt
```

## Performance Tips

1. **Minimize delays** - Only use sleep when necessary
2. **Reuse tabs** - Switch to existing tabs instead of opening new ones
3. **Batch operations** - Process multiple items in single page load
4. **Cache tab indices** - Store tab positions if switching frequently
5. **Parallel execution** - Run multiple scripts for different tabs

## Security Considerations

1. **Sensitive data** - Be cautious with passwords and API keys
2. **Base64 is not encryption** - Only for safe text transmission
3. **JavaScript execution** - Only run trusted JavaScript code
4. **Automation permissions** - Grant only to trusted applications
5. **Log sanitization** - Don't log sensitive information

## Related Scripts

- **08-sota-posts-to-linkedin.sh** - Complete LinkedIn automation example
- **02-launch-chrome-profile.sh** - Launch Chrome with specific profile
- **open-chrome-with-bookmarks.sh** - Open multiple tabs at once

## Contributing

When extending this script:

1. Follow the existing function naming convention
2. Add comprehensive error handling
3. Use base64 encoding for text transmission
4. Return JSON from JavaScript for structured data
5. Add logging for all major operations
6. Update this README with new features

## License

Part of the my-browser-control project.

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review the skills documentation in `skills/07-applescript-automation.md`
3. Examine the working example in `scripts/08-sota-posts-to-linkedin.sh`
