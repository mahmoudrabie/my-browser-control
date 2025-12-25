# AppleScript Automation - Quick Reference

## One-Time Setup ⚙️

```bash
# Enable JavaScript from Apple Events in Chrome
# View → Developer → Allow JavaScript from Apple Events ✓
```

## Core Scripts 🎯

### Main Automation Framework
```bash
# Basic usage
./scripts/applescript-full-automation.sh

# Custom URL and text
./scripts/applescript-full-automation.sh "https://example.com" "Your text"

# Help
./scripts/applescript-full-automation.sh --help
```

### LinkedIn Posting Workflow
```bash
# Auto-post from SOTA to LinkedIn
./scripts/08-sota-posts-to-linkedin.sh

# Custom tab hints
SOTA_TAB_HINT="MyTab" LINKEDIN_TAB_HINT="linkedin" \
  ./scripts/08-sota-posts-to-linkedin.sh
```

## Example Scripts 📚

### Text Processing
```bash
# Interactive mode
./scripts/examples/text-processor-example.sh interactive

# Single text
./scripts/examples/text-processor-example.sh single "Text here"

# Batch process
./scripts/examples/text-processor-example.sh batch input.txt
```

### Tab Management
```bash
# List all tabs
./scripts/examples/multi-tab-example.sh list

# Switch to tab 3
./scripts/examples/multi-tab-example.sh switch 3

# Copy from tab 2 to tab 5
./scripts/examples/multi-tab-example.sh copy 2 5

# Get current tab info
./scripts/examples/multi-tab-example.sh info
```

## Quick AppleScript Patterns 🔧

### Navigate to URL
```applescript
tell application "Google Chrome"
    set URL of active tab of front window to "https://example.com"
end tell
```

### Execute JavaScript
```applescript
tell application "Google Chrome"
    execute front window's active tab javascript "document.title"
end tell
```

### Switch Tab by URL
```applescript
tell application "Google Chrome"
    repeat with t in tabs of front window
        if URL of t contains "example.com" then
            set active tab index of front window to index of t
        end if
    end repeat
end tell
```

### Fill Form Field
```applescript
tell application "Google Chrome"
    execute front window's active tab javascript "
        const input = document.querySelector('input');
        input.value = 'text';
        input.dispatchEvent(new Event('input', { bubbles: true }));
    "
end tell
```

## Bash Helper Functions 🛠️

### Base64 Encode/Decode
```bash
# Encode
text_b64=$(echo "$text" | b64_encode)

# Decode
text=$(echo "$text_b64" | b64_decode)
```

### Chrome Status Check
```bash
if chrome_check_running; then
    echo "Chrome is ready"
fi
```

### Extract Text
```bash
result=$(chrome_extract_text)
text=$(echo "$result" | jq -r '.text')
```

### Fill and Submit
```bash
text_b64=$(echo "My text" | b64_encode)
chrome_fill_and_submit "$text_b64" "submit"
```

## Common Workflows 🔄

### Workflow 1: Single Page Automation
```bash
chrome_navigate_to "https://example.com" 3
text_b64=$(echo "input text" | b64_encode)
chrome_fill_and_submit "$text_b64" "submit"
sleep 2
result=$(chrome_extract_text)
```

### Workflow 2: Multi-Tab Processing
```bash
chrome_switch_to_tab "source.com"
text=$(get_tab_text)
chrome_switch_to_tab "dest.com"
echo "$text" | b64_encode | xargs -I {} chrome_fill_and_submit {}
```

### Workflow 3: Batch Processing
```bash
while read -r line; do
    ./applescript-full-automation.sh "https://example.com" "$line"
done < input.txt
```

## Troubleshooting 🔍

### Check Prerequisites
```bash
# Chrome running?
osascript -e 'tell application "Google Chrome" to activate'

# JavaScript enabled?
# View → Developer → Allow JavaScript from Apple Events ✓

# Automation permissions?
# System Settings → Privacy & Security → Automation
```

### Debug Mode
```bash
# Add to your script
set -x  # Enable
# ... your code ...
set +x  # Disable
```

### Test Individual Parts
```bash
# List tabs
./scripts/examples/multi-tab-example.sh list

# Get page info
./scripts/examples/multi-tab-example.sh info

# Extract text
./scripts/examples/multi-tab-example.sh text | head -20
```

## Documentation 📖

- **Comprehensive Guide**: `scripts/APPLESCRIPT-AUTOMATION-GUIDE.md`
- **Examples Guide**: `scripts/examples/README.md`
- **Skills Doc**: `skills/07-applescript-automation.md`
- **Main Script**: `scripts/applescript-full-automation.sh`

## Key Features ✨

✅ Uses your actual Chrome profile  
✅ Works with logged-in sessions  
✅ Access to your extensions  
✅ Tab switching and management  
✅ No browser extensions needed  
✅ Safe text handling (UTF-8, special chars)  
✅ Comprehensive error handling  
✅ JSON response validation  
✅ Clipboard integration  
✅ Flexible and extensible  

## Quick Tips 💡

1. **Always wait after navigation**: `sleep 2` or `delay 2`
2. **Dispatch events for React/Vue**: `dispatchEvent(new Event('input'))`
3. **Use base64 for special characters**: Avoids quote escaping issues
4. **Check return values**: Use JSON for structured responses
5. **Test incrementally**: Test each step before combining
6. **Keep Chrome visible**: Helps with debugging and verification
7. **Grant permissions when prompted**: Required for automation
8. **Use clipboard as fallback**: `pbcopy` for manual paste option

## Common Selectors 🎯

```javascript
// Textareas
document.querySelector('textarea')
document.querySelectorAll('textarea')[1]  // Second one

// Buttons by text
Array.from(document.querySelectorAll('button'))
    .find(b => b.textContent.includes('Submit'))

// Inputs
document.querySelector('input[type="text"]')
document.querySelector('[contenteditable="true"]')

// Output elements
document.querySelector('.output, .result')
document.querySelector('[id*="output"]')
```

## Environment Variables 🔧

```bash
# Create .env file in project root
DEFAULT_URL="https://yourdefault.com"
DEFAULT_TEXT="Your default text"
SOTA_TAB_HINT="SOTA-Posts"
LINKEDIN_TAB_HINT="linkedin.com"
CLEAN_TAB_HINT="cleanpaste.site"
```

## Performance Tips ⚡

- Minimize delays (only when needed)
- Reuse existing tabs (don't create new ones)
- Batch operations when possible
- Use parallel execution for independent tasks
- Cache tab indices if switching frequently

---

**Need more help?** Check the comprehensive guides in the `scripts/` directory!
