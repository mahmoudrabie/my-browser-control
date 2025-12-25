# AppleScript Automation Examples

This directory contains practical examples demonstrating how to use the AppleScript Chrome automation framework.

## Available Examples

### 1. Text Processor (`text-processor-example.sh`)

Demonstrates text processing workflows with single, batch, and interactive modes.

**Features:**
- Process single text strings
- Batch process from files
- Interactive stdin mode
- Pipeline integration

**Usage:**
```bash
# Interactive mode
./text-processor-example.sh interactive

# Single text processing
./text-processor-example.sh single "Text to process"

# Batch processing from file
./text-processor-example.sh batch input.txt output.txt

# Pipeline
echo "Text here" | ./text-processor-example.sh interactive
```

**Use Cases:**
- Clean up copied text before pasting
- Process multiple items from a list
- Integrate with other command-line tools

---

### 2. Multi-Tab Manager (`multi-tab-example.sh`)

Advanced tab management and cross-tab workflows.

**Features:**
- List all open Chrome tabs
- Switch between tabs by number
- Extract text from any tab
- Create and close tabs
- Copy content between tabs

**Usage:**
```bash
# List all tabs
./multi-tab-example.sh list

# Switch to tab 3
./multi-tab-example.sh switch 3

# Get current tab info
./multi-tab-example.sh info

# Extract text from current tab
./multi-tab-example.sh text

# Create new tab
./multi-tab-example.sh new "https://example.com"

# Copy from tab 2 to tab 5
./multi-tab-example.sh copy 2 5

# Close current tab
./multi-tab-example.sh close
```

**Use Cases:**
- Monitor multiple tabs programmatically
- Extract data from specific tabs
- Coordinate multi-tab workflows
- Build tab-switching automation

---

## Creating Your Own Examples

### Template Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Import automation framework functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUTOMATION_SCRIPT="$ROOT_DIR/scripts/applescript-full-automation.sh"

# 2. Define your custom functions
your_function() {
    local param="$1"
    # Your logic here
}

# 3. Main interface
main() {
    case "${1:-help}" in
        your-command)
            your_function "$2"
            ;;
        *)
            echo "Usage: $0 your-command [ARGS]"
            ;;
    esac
}

main "$@"
```

### Common Patterns

#### Pattern 1: Navigate and Extract

```bash
# Navigate to page
chrome_navigate_to "https://example.com" 3

# Extract content
result=$(chrome_extract_text)
echo "$result" | jq -r '.text'
```

#### Pattern 2: Multi-Step Form Filling

```bash
# Step 1: Fill first field
text_b64=$(echo "value1" | b64_encode)
chrome_fill_field "$text_b64" "input[name='field1']"

# Step 2: Fill second field
text_b64=$(echo "value2" | b64_encode)
chrome_fill_field "$text_b64" "input[name='field2']"

# Step 3: Submit
chrome_click_button "submit"
```

#### Pattern 3: Tab Orchestration

```bash
# List tabs to find what you need
chrome_list_tabs

# Switch to specific tab
chrome_switch_to_tab "linkedin.com"

# Do something
chrome_fill_and_submit "$data" "post"

# Switch to another tab
chrome_switch_to_tab "twitter.com"
```

#### Pattern 4: Error Recovery

```bash
# Try primary method
if ! chrome_navigate_to "$URL" 3; then
    log_error "Primary method failed, trying fallback"
    
    # Fallback: try to find existing tab
    if chrome_switch_to_tab "$URL_HINT"; then
        log_success "Found existing tab"
    else
        log_error "All methods failed"
        exit 1
    fi
fi
```

---

## Best Practices

### 1. Always Check Chrome Status
```bash
if ! chrome_check_running; then
    echo "Error: Chrome is not running"
    exit 1
fi
```

### 2. Use Base64 for Text Safety
```bash
# Encode
text_b64=$(echo "$text" | b64_encode)

# Decode
text=$(echo "$text_b64" | b64_decode)
```

### 3. Add Appropriate Delays
```bash
chrome_navigate_to "$URL" 3  # 3 second delay
sleep 1  # Additional wait if needed
```

### 4. Validate Results
```bash
result=$(chrome_extract_text)
if echo "$result" | jq -e '.ok' >/dev/null; then
    echo "Success!"
else
    echo "Failed!"
fi
```

### 5. Provide User Feedback
```bash
log "Starting process..."
log_success "Step 1 complete"
log_error "Step 2 failed"
```

---

## Integration Examples

### With jq (JSON processing)
```bash
result=$(chrome_get_page_info)
title=$(echo "$result" | jq -r '.title')
url=$(echo "$result" | jq -r '.url')
```

### With curl (API integration)
```bash
text=$(chrome_extract_text | jq -r '.text')
curl -X POST https://api.example.com/process \
    -d "text=$text"
```

### With other scripts
```bash
# Extract from Chrome
data=$(./multi-tab-example.sh text)

# Process with another tool
processed=$(echo "$data" | ./your-processor.sh)

# Send back to Chrome
echo "$processed" | ./text-processor-example.sh interactive
```

---

## Troubleshooting Examples

### Debug Mode
Add this to your scripts for verbose output:
```bash
set -x  # Enable debug mode
# Your code here
set +x  # Disable debug mode
```

### Check What's Available
```bash
# List tabs to see what's open
./multi-tab-example.sh list

# Get current tab info
./multi-tab-example.sh info

# Extract text to see what's there
./multi-tab-example.sh text | head -20
```

### Test Individual Components
```bash
# Test navigation
chrome_navigate_to "https://example.com" 3

# Test text extraction
chrome_extract_text | jq '.'

# Test form filling
echo "test" | b64_encode | xargs -I {} chrome_fill_and_submit {}
```

---

## Contributing Examples

When contributing new examples:

1. **Follow naming convention**: `purpose-example.sh`
2. **Include help text**: Support `--help` flag
3. **Add comprehensive comments**: Explain what each part does
4. **Handle errors gracefully**: Check prerequisites and validate inputs
5. **Update this README**: Add your example to the list

### Example Submission Checklist

- [ ] Script has executable permissions (`chmod +x`)
- [ ] Passes bash syntax check (`bash -n script.sh`)
- [ ] Has help documentation (`script.sh --help`)
- [ ] Includes error handling
- [ ] Has usage examples in comments
- [ ] Added to this README
- [ ] Tested on macOS with Chrome

---

## Additional Resources

- **Main Framework**: [`scripts/applescript-full-automation.sh`](../applescript-full-automation.sh)
- **Comprehensive Guide**: [`scripts/APPLESCRIPT-AUTOMATION-GUIDE.md`](../APPLESCRIPT-AUTOMATION-GUIDE.md)
- **Skills Documentation**: [`skills/07-applescript-automation.md`](../../skills/07-applescript-automation.md)
- **LinkedIn Example**: [`scripts/08-sota-posts-to-linkedin.sh`](../08-sota-posts-to-linkedin.sh)

---

## Need Help?

1. Check the main guide: `APPLESCRIPT-AUTOMATION-GUIDE.md`
2. Review working examples in this directory
3. Test with the multi-tab manager to understand your current state
4. Use `set -x` for debugging

Happy automating! 🚀
