# LinkedIn Post Scheduler Skill

## Description
Automate creating and scheduling LinkedIn posts from content in ChatGPT tabs.

## Prerequisites
- Google Chrome with LinkedIn logged in
- ChatGPT tabs with posts ready to copy
- Clean Paste tab open (https://cleanpaste.site)

## Validation Strategy
**Every step must be validated before proceeding to the next step.**

| Validation Type | Method | Minimum |
|-----------------|--------|---------|
| Tab navigation | Check return value "found" | - |
| Clipboard content | `pbpaste \| wc -c` | 100 chars |
| Textarea content | JS `querySelector('textarea').value.length` | 100 chars |

## Full Workflow Overview

### Disciplines and Schedule
| Discipline | ChatGPT GPT ID | Schedule Time | Google Sheet Column |
|------------|----------------|---------------|---------------------|
| SOTA-Posts | 689731221e7881919f3f0b3b80f70f6b | 11:00 AM | B |
| Agentic-AI-Search | 687b4667bb988191ac0aa4a96358607f | 12:00 PM | C |
| cyber-security-highlights | 6895b9c4ec188191a8322d5955fc76ef | 1:00 PM | D |
| open-source-AI-Projects | 689f374e6008819182ed6cb8d6d93826 | 2:00 PM | E |
| open-source-llms | 68a26a3f484c8191b33389a508d57685 | 3:00 PM | F |

## Workflow Steps (with Validation)

### Step 1: Clear Clipboard
```bash
pbcopy < /dev/null
# Validate
[ $(pbpaste | wc -c) -eq 0 ] && echo "✅ Clipboard cleared" || echo "❌ Failed"
```

### Step 2: Copy Content from ChatGPT Tab (PROVEN METHOD)

**Key Learning**: Clicking the Copy button via JavaScript does NOT work due to browser clipboard security restrictions. Instead, extract text directly from the DOM and pipe to `pbcopy`.

```bash
# Navigate to ChatGPT tab by GPT ID
osascript <<EOF
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "GPT_ID_HERE" then
                set active tab index of w to tabIndex
                set index of w to 1
                activate
                exit repeat
            end if
            set tabIndex to tabIndex + 1
        end repeat
    end repeat
end tell
EOF
sleep 0.5

# Scroll to bottom
osascript <<EOF
tell application "System Events"
    key code 119 using command down
    delay 0.8
end tell
EOF

# PROVEN: Extract text directly from DOM (bypasses clipboard security)
osascript <<'EOF' | pbcopy
tell application "Google Chrome"
    tell active tab of front window
        set postText to execute javascript "
            // Get the last assistant message content
            var msgs = document.querySelectorAll('[data-message-author-role=\"assistant\"]');
            if (msgs.length > 0) {
                var lastMsg = msgs[msgs.length - 1];
                var content = lastMsg.querySelector('.markdown');
                if (content) {
                    content.innerText;
                } else {
                    lastMsg.innerText;
                }
            } else {
                '';
            }
        "
        return postText
    end tell
end tell
EOF
```

**Why this works**: 
- `execute javascript` returns text content to AppleScript
- AppleScript returns it to stdout
- `| pbcopy` captures it into the clipboard
- No browser clipboard API needed!

### Step 3: Verify Clipboard Has Content
```bash
content=$(pbpaste)
char_count=${#content}
echo "Character count: $char_count"
```

### Step 4: Go to Clean Paste and Refresh
```applescript
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "cleanpaste" then
                set active tab index of w to tabIndex
                set index of w to 1
                activate
                exit repeat
            end if
            set tabIndex to tabIndex + 1
        end repeat
    end repeat
end tell
delay 0.5

-- Refresh the page
tell application "System Events"
    keystroke "r" using command down
end tell
delay 2.5
```

### Step 5: Paste Content to Clean Paste
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var textarea = document.querySelector('textarea');
            if (textarea) { textarea.focus(); textarea.click(); }
        "
    end tell
end tell
delay 0.3

tell application "System Events"
    keystroke "v" using command down
    delay 0.5
end tell
```

### Step 6: Click Clean Text Button
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                if (btns[i].innerText && btns[i].innerText.indexOf('Clean') !== -1) {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
delay 3
```

### Step 7: Close Share Modal (if appears)
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                if (btns[i].innerText && btns[i].innerText.indexOf('No thanks') !== -1) {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
delay 0.5
```

### Step 8: Extract Cleaned Text via JavaScript (Automated)
Instead of clicking the Copy button (which requires HITL due to browser clipboard security), we extract the cleaned text directly from the DOM and pipe it to `pbcopy`:

```bash
# Extract cleaned text via JavaScript and copy to clipboard
cleaned_text=$(osascript <<EOF
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            // Try multiple selectors to find the cleaned text output
            var cleanedText = '';
            
            // Look for output textarea or div with cleaned content
            var outputArea = document.querySelector('.cleaned-output, #cleaned-output, [data-cleaned], textarea[readonly]');
            if (outputArea) {
                cleanedText = outputArea.value || outputArea.innerText || outputArea.textContent;
            }
            
            // Fallback: look for the second textarea (output)
            if (!cleanedText) {
                var textareas = document.querySelectorAll('textarea');
                if (textareas.length > 1) {
                    cleanedText = textareas[1].value || textareas[1].innerText;
                }
            }
            
            // Fallback: look for pre or code block with output
            if (!cleanedText) {
                var pre = document.querySelector('pre, code');
                if (pre) cleanedText = pre.innerText || pre.textContent;
            }
            
            cleanedText;
        "
    end tell
end tell
EOF
)

# Copy to clipboard using pbcopy (bypasses browser security)
echo -n "$cleaned_text" | pbcopy
```

**Key Insight**: Browser security blocks JavaScript `navigator.clipboard.writeText()` from AppleScript, but we can extract the text content directly from the DOM and use macOS `pbcopy` to copy it to clipboard.

### Step 9: Verify Cleaned Content in Clipboard
```bash
content=$(pbpaste)
char_count=${#content}
echo "Cleaned content character count: $char_count"
# LinkedIn limit is 3000 characters
if [ $char_count -gt 3000 ]; then
    echo "WARNING: Exceeds LinkedIn's 3000 character limit!"
fi
```

### Step 10: Go to LinkedIn and Open Post Dialog
```applescript
-- Activate Chrome first
tell application "Google Chrome"
    activate
end tell
delay 0.3

-- Go to LinkedIn tab
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "linkedin.com" then
                set active tab index of w to tabIndex
                set index of w to 1
                activate
                exit repeat
            end if
            set tabIndex to tabIndex + 1
        end repeat
    end repeat
end tell
delay 0.8

-- Scroll to top
tell application "System Events"
    key code 116 using command down
    delay 0.5
end tell

-- Click Start a post
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                if (btns[i].innerText && btns[i].innerText.indexOf('Start a post') !== -1) {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
delay 2
```

### Step 11: Focus Post Editor (CRITICAL)
**Must focus the editor before pasting, otherwise paste goes to wrong window!**

```applescript
tell application "Google Chrome"
    activate
    delay 0.3
    tell active tab of front window
        execute javascript "
            // Find the post editor in the modal dialog
            var editor = document.querySelector('.ql-editor[contenteditable=\"true\"]');
            if (!editor) {
                var modal = document.querySelector('[role=\"dialog\"]');
                if (modal) {
                    editor = modal.querySelector('[contenteditable=\"true\"]');
                }
            }
            if (editor) {
                editor.focus();
                editor.click();
            }
        "
    end tell
end tell
delay 0.3
```

### Step 12: Paste Cleaned Content
**Use `tell process "Google Chrome"` to ensure paste goes to Chrome:**
```applescript
tell application "System Events"
    tell process "Google Chrome"
        keystroke "v" using command down
    end tell
end tell
delay 1.0
```

### Step 13: Click Clock Icon for Scheduling
**JavaScript Approach** - Click the clock icon using `aria-label`:
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                var ariaLabel = btns[i].getAttribute('aria-label') || '';
                if (ariaLabel === 'Schedule post') {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
delay 1.5
```

**Note**: If JavaScript click doesn't work, manual click may be required (HITL).

### Step 14: Set Time using Keyboard
```applescript
tell application "Google Chrome" to activate
delay 0.3
tell application "System Events"
    -- Tab to time field
    keystroke tab
    delay 0.2
    keystroke tab
    delay 0.2
    -- Select all and type new time
    keystroke "a" using command down
    delay 0.2
    keystroke "11:00 AM"  -- Replace with desired time
    delay 0.3
    -- Press Enter to confirm
    key code 36
end tell
```

### Step 14: Click Next Button
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                var txt = (btns[i].innerText || '').trim();
                if (txt === 'Next') {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
delay 1.5
```

### Step 15: Click Schedule to Confirm
```applescript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                if ((btns[i].innerText || '').trim() === 'Schedule') {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
```

## Important Notes
- LinkedIn has a 3,000 character limit for posts
- LinkedIn only allows ONE draft at a time - use scheduling instead for multiple posts
- Always clean content to remove invisible AI watermark characters
- Schedule times: 11:00 AM, 12:00 PM, 1:00 PM, 2:00 PM, 3:00 PM (1 hour apart)

## Complete 19-Step Workflow (All Steps Validated Dec 2025)

| Step | Description | Status |
|------|-------------|--------|
| **ChatGPT Phase** | | |
| 1 | Clear clipboard | ✅ Proven |
| 2 | Navigate to ChatGPT tab by GPT ID | ✅ Proven |
| 3 | Scroll to bottom (Cmd+End) | ✅ Proven |
| 4 | Extract text from DOM → pbcopy | ✅ Proven |
| **Clean Paste Phase** | | |
| 5 | Navigate to Clean Paste tab | ✅ Proven |
| 6 | Refresh page (Cmd+R) | ✅ Proven |
| 7 | Focus textarea and paste (Cmd+V) | ✅ Proven |
| 8 | Click "Clean Text" button | ✅ Proven |
| 9 | Close "No thanks" modal if present | ✅ Proven |
| 10 | Extract cleaned text from 2nd textarea → pbcopy | ✅ Proven |
| **LinkedIn Phase** | | |
| 11 | Navigate to LinkedIn tab | ✅ Proven |
| 12 | Scroll to top (Cmd+Home) | ✅ Proven |
| 13 | Click "Start a post" button | ✅ Proven |
| 14 | Focus .ql-editor and paste (Cmd+V) | ✅ Proven |
| **Scheduling Phase** | | |
| 15 | Click clock icon (aria-label="Schedule post") | ✅ Proven |
| 16 | Set date (focus input[0] + select + keystroke) | ✅ Proven |
| 17 | Set time (focus input[1] + select + keystroke) | ✅ Proven |
| 18 | Click "Next" button | ✅ Proven |
| 19 | Click "Schedule" button | ✅ Proven |

## Key Learnings (All Validated Dec 2025)

### ✅ Pattern 1: DOM Text Extraction (Bypasses Browser Security)
Extract text directly from DOM and pipe to pbcopy - bypasses browser clipboard security:
```bash
osascript <<'EOF' | pbcopy
tell application "Google Chrome"
    tell active tab of front window
        set postText to execute javascript "
            var msgs = document.querySelectorAll('[data-message-author-role=\"assistant\"]');
            if (msgs.length > 0) {
                var lastMsg = msgs[msgs.length - 1];
                var content = lastMsg.querySelector('.markdown');
                content ? content.innerText : lastMsg.innerText;
            } else { ''; }
        "
        return postText
    end tell
end tell
EOF
```

### ❌ Pattern 2: Clicking Copy Buttons (DOES NOT WORK)
Browser security blocks clipboard writes from JavaScript triggered via AppleScript:
```applescript
-- THIS DOES NOT COPY TO CLIPBOARD (security restriction)
execute javascript "document.querySelector('button[aria-label=\"Copy\"]').click()"
```

### ✅ Pattern 3: JavaScript Click (Always Prefer Over Coordinates)
**Always prefer JavaScript clicks over coordinate-based clicks:**
```applescript
-- RELIABLE: JavaScript click (works on any screen resolution)
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                if ((btns[i].innerText || '').trim() === 'ButtonText') {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
```

### ✅ Pattern 4: Focus Before Paste (CRITICAL)
Must activate Chrome AND focus element via JS before keystroke:
```applescript
-- STEP 1: Activate Chrome
tell application "Google Chrome" to activate
delay 0.3

-- STEP 2: Focus the target element via JavaScript
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var editor = document.querySelector('.ql-editor');
            if (editor) { editor.focus(); editor.click(); }
        "
    end tell
end tell
delay 0.3

-- STEP 3: Paste using tell process (ensures Chrome receives it)
tell application "System Events"
    tell process "Google Chrome"
        keystroke "v" using command down
    end tell
end tell
```

### ✅ Pattern 5: Input Field Setting (Focus + Select + Delete + Keystroke)
For date/time inputs, use focus + select + delete + keystroke (calendar pickers don't work):

**CRITICAL: Date format must be MM/DD/YYYY (e.g., 12/28/2025), NOT "December 28, 2025"**

```applescript
-- Focus and select input via JavaScript
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "
            var input = document.querySelectorAll('input')[0];  -- date input
            input.focus();
            input.select();
        "
    end tell
end tell
delay 0.2

-- Delete selected text then type new value via System Events
tell application "System Events"
    tell process "Google Chrome"
        key code 51  -- Backspace to delete selected text
        delay 0.2
        keystroke "12/28/2025"  -- Format: MM/DD/YYYY (REQUIRED)
    end tell
end tell
```

### ✅ Pattern 6: Clean Paste Extraction (Second Textarea)
The cleaned text is always in the second textarea:
```applescript
execute javascript "
    var textareas = document.querySelectorAll('textarea');
    if (textareas.length > 1) {
        textareas[1].value;
    } else { ''; }
"
```

### ✅ Pattern 7: Reliable Page Refresh (JavaScript location.reload)
**CRITICAL**: `Cmd+R` can fail silently. Use JavaScript `location.reload()` and VERIFY textarea is empty:
```bash
# Refresh using JavaScript (more reliable than Cmd+R)
osascript <<'EOF'
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "location.reload()"
    end tell
end tell
EOF
sleep 3

# MUST VALIDATE: Textarea should be 0 chars after refresh
textarea_len=$(osascript <<'EOF'
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "document.querySelector('textarea').value.length"
    end tell
end tell
EOF
)
[ "$textarea_len" -eq 0 ] && echo "✅ Refresh validated" || echo "❌ Refresh failed, retry"
```

### ✅ Pattern 8: Character Count Check (LinkedIn 3000 char limit)
**Before pasting to LinkedIn, verify cleaned text is under 3000 chars:**
```bash
char_count=$(pbpaste | wc -c | tr -d ' ')
if [ "$char_count" -gt 3000 ]; then
    echo "❌ Content exceeds 3000 chars ($char_count). Go back to ChatGPT and request shorter version."
    # Navigate back to ChatGPT and ask:
    # "Please reduce the post to be less than 3000 characters while keeping the same format style and titles"
else
    echo "✅ Content is $char_count chars (under 3000 limit)"
fi
```

### ✅ Pattern 9: LinkedIn Feed Refresh Before New Post
**Always refresh LinkedIn feed before clicking "Start a post" to ensure clean state:**
```applescript
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "location.reload()"
    end tell
end tell
delay 3
```

## Google Sheet Update
After all posts are scheduled, update row 273 (date 2025-12-26) with normalized titles:
- Column B: SOTA title
- Column C: Agentic AI title
- Column D: Cybersecurity title
- Column E: Open Source AI Projects title
- Column F: Open Source LLMs title
