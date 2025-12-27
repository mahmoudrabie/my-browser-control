#!/bin/bash
# ChatGPT to LinkedIn Post Scheduler
#
# CRITICAL: This script starts by inspecting the opened Chrome window tabs.
# No new Chrome windows are opened - works with existing tabs only.
#
# Complete 19-Step Workflow (All Validated Dec 2025):
#
# Step 0: Inspect Chrome Window (MANDATORY FIRST STEP)
#   - Verify single Chrome window exists
#   - Detect and validate all required tabs (ChatGPT, CleanPaste, LinkedIn)
#
# ChatGPT Phase:
#   1. Clear clipboard
#   2. Navigate to ChatGPT tab by GPT ID
#   3. Scroll to bottom (Cmd+End)
#   4. Extract text from DOM → pbcopy
#
# Clean Paste Phase:
#   5. Navigate to Clean Paste tab
#   6. Refresh page (Cmd+R)
#   7. Focus textarea and paste (Cmd+V)
#   8. Click "Clean Text" button
#   9. Close "No thanks" modal if present
#   10. Extract cleaned text from 2nd textarea → pbcopy
#
# LinkedIn Phase:
#   11. Navigate to LinkedIn tab
#   12. Scroll to top (Cmd+Home)
#   13. Click "Start a post" button
#   14. Focus .ql-editor and paste (Cmd+V)
#
# Scheduling Phase:
#   15. Click clock icon (aria-label="Schedule post")
#   16. Set date (focus input[0] + select + keystroke)
#   17. Set time (focus input[1] + select + keystroke)
#   18. Click "Next" button
#   19. Click "Schedule" button
#
# Usage: ./16-chatgpt-to-linkedin-scheduler.sh
#
# All 19 steps are fully automated - NO HITL required!

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ChatGPT GPT IDs for each discipline
declare -A GPT_IDS=(
    ["SOTA"]="689731221e7881919f3f0b3b80f70f6b"
    ["AgenticAI"]="687b4667bb988191ac0aa4a96358607f"
    ["Cybersecurity"]="6895b9c4ec188191a8322d5955fc76ef"
    ["OpenSourceAIProjects"]="689f374e6008819182ed6cb8d6d93826"
    ["OpenSourceLLMs"]="68a26a3f484c8191b33389a508d57685"
)

# Schedule times (1 hour apart starting at 1:00 PM)
declare -A SCHEDULE_TIMES=(
    ["SOTA"]="1:00 PM"
    ["AgenticAI"]="2:00 PM"
    ["Cybersecurity"]="3:00 PM"
    ["OpenSourceAIProjects"]="4:00 PM"
    ["OpenSourceLLMs"]="5:00 PM"
)

# Google Sheet columns
declare -A SHEET_COLUMNS=(
    ["SOTA"]="B"
    ["AgenticAI"]="C"
    ["Cybersecurity"]="D"
    ["OpenSourceAIProjects"]="E"
    ["OpenSourceLLMs"]="F"
)

# ============================================================
# STEP 0: Chrome Window/Tab Inspection (MANDATORY FIRST STEP)
# ============================================================

# Verify Chrome has window open and get tab counts
inspect_chrome_window() {
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then return "error:No Chrome windows open"
    
    set windowCount to count of windows
    set win to front window
    set tabCount to count of tabs of win
    set activeIdx to active tab index of win
    
    return "ok:" & windowCount & ":" & tabCount & ":" & activeIdx
end tell
APPLESCRIPT
}

# Detect all required tabs for the 19-step workflow
detect_required_tabs() {
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then return "error:No Chrome windows open"
    
    set win to front window
    set chatgptFound to false
    set cleanpasteFound to false
    set linkedinFound to false
    set sheetFound to false
    
    repeat with i from 1 to count of tabs of win
        set t to tab i of win
        set tabURL to URL of t
        set tabTitle to title of t
        
        -- Check for ChatGPT tabs (any GPT)
        if tabURL contains "chatgpt.com" then
            set chatgptFound to true
        end if
        
        -- Check for Clean Paste tab
        if tabURL contains "cleanpaste" then
            set cleanpasteFound to true
        end if
        
        -- Check for LinkedIn feed/post tab
        if tabURL contains "linkedin.com" then
            set linkedinFound to true
        end if
        
        -- Check for Google Sheet tab
        if tabURL contains "docs.google.com/spreadsheets" then
            set sheetFound to true
        end if
    end repeat
    
    -- Build missing list
    set missingList to {}
    if not chatgptFound then set end of missingList to "ChatGPT"
    if not cleanpasteFound then set end of missingList to "CleanPaste"
    if not linkedinFound then set end of missingList to "LinkedIn"
    if not sheetFound then set end of missingList to "GoogleSheet"
    
    if (count of missingList) = 0 then
        return "ok:all tabs found"
    else
        set AppleScript's text item delimiters to ","
        set missingStr to missingList as string
        set AppleScript's text item delimiters to ""
        return "missing:" & missingStr
    end if
end tell
APPLESCRIPT
}

# Initialize and validate Chrome window and tabs
init_chrome_window() {
    echo "Step 0: Inspecting opened Chrome window..."
    echo ""
    
    # First verify Chrome window exists
    local window_info
    window_info=$(inspect_chrome_window)
    
    if [[ "$window_info" == error:* ]]; then
        echo "  ❌ ERROR: ${window_info#error:}"
        echo "  Please open Chrome with required tabs before running this script."
        exit 1
    fi
    
    # Parse window info: ok:windowCount:tabCount:activeIdx
    IFS=':' read -r status windowCount tabCount activeIdx <<< "$window_info"
    echo "  ✅ Chrome windows: $windowCount"
    echo "  ✅ Front window tabs: $tabCount"
    echo "  ✅ Active tab: #$activeIdx"
    echo ""
    
    # Detect required tabs
    echo "  Checking for required tabs..."
    local tab_check
    tab_check=$(detect_required_tabs)
    
    if [[ "$tab_check" == missing:* ]]; then
        local missing="${tab_check#missing:}"
        echo "  ❌ ERROR: Missing tabs: $missing"
        echo ""
        echo "  Required tabs:"
        echo "    - ChatGPT (with GPT conversations)"
        echo "    - Clean Paste (cleanpaste.site)"
        echo "    - LinkedIn (feed or profile)"
        echo "    - Google Sheet (My Selected Sources)"
        echo ""
        echo "  Please open all required tabs and try again."
        exit 1
    fi
    
    echo "  ✅ All required tabs found:"
    echo "    - ChatGPT ✓"
    echo "    - CleanPaste ✓"
    echo "    - LinkedIn ✓"
    echo "    - GoogleSheet ✓"
    echo ""
}

# ============================================================

# Function: Navigate to Chrome tab by URL pattern
# Returns: "found" or "not found"
navigate_to_tab() {
    local url_pattern="$1"
    local result
    result=$(osascript <<EOF
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "$url_pattern" then
                set active tab index of w to tabIndex
                set index of w to 1
                activate
                return "found"
            end if
            set tabIndex to tabIndex + 1
        end repeat
    end repeat
    return "not found"
end tell
EOF
)
    echo "$result"
}

# Function: Validate clipboard has content
# Args: $1 = minimum expected chars, $2 = step description
validate_clipboard() {
    local min_chars="${1:-1}"
    local step_desc="${2:-clipboard check}"
    local char_count
    char_count=$(pbpaste | wc -c | tr -d ' ')
    
    if [ "$char_count" -ge "$min_chars" ]; then
        echo "  ✅ VALIDATED: $step_desc - $char_count chars in clipboard"
        return 0
    else
        echo "  ❌ FAILED: $step_desc - only $char_count chars (expected >= $min_chars)"
        return 1
    fi
}

# Function: Copy from ChatGPT tab
# PROVEN: Extract text directly from DOM (clicking Copy button doesn't work due to browser clipboard security)
copy_from_chatgpt() {
    local gpt_id="$1"
    local nav_result

    # Step 1: Navigate to the ChatGPT tab
    echo "  [1/3] Navigating to ChatGPT tab..."
    nav_result=$(navigate_to_tab "$gpt_id")
    if [ "$nav_result" != "found" ]; then
        echo "  ❌ FAILED: Could not find ChatGPT tab with GPT ID: $gpt_id"
        return 1
    fi
    echo "  ✅ VALIDATED: Found ChatGPT tab"
    sleep 0.5

    # Step 2: Scroll to bottom
    echo "  [2/3] Scrolling to bottom..."
    osascript <<EOF
tell application "System Events"
    key code 119 using command down
    delay 0.8
end tell
EOF
    echo "  ✅ Scrolled to bottom"

    # Step 3: Extract post text directly from DOM and copy to clipboard
    echo "  [3/3] Extracting text from DOM..."
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

    # Validate clipboard has content
    validate_clipboard 100 "ChatGPT text extraction"
}

# Function: Clean content via Clean Paste website
# Automated: Extracts cleaned text via JavaScript instead of clicking Copy button
clean_via_cleanpaste() {
    local nav_result
    local input_chars
    local textarea_chars
    
    # Save original clipboard content char count for validation
    input_chars=$(pbpaste | wc -c | tr -d ' ')
    echo "  [1/6] Input content: $input_chars chars"
    
    # Step 1: Navigate to Clean Paste
    echo "  [2/6] Navigating to Clean Paste..."
    nav_result=$(navigate_to_tab "cleanpaste")
    if [ "$nav_result" != "found" ]; then
        echo "  ❌ FAILED: Could not find Clean Paste tab"
        return 1
    fi
    echo "  ✅ VALIDATED: Found Clean Paste tab"
    sleep 0.5

    # Step 2: Refresh page
    echo "  [3/6] Refreshing page..."
    osascript <<EOF
tell application "System Events"
    keystroke "r" using command down
end tell
delay 2.5
EOF
    echo "  ✅ Page refreshed"

    # Step 3: Paste content via JavaScript (set value directly)
    echo "  [4/6] Pasting content to textarea..."
    
    # First, get the clipboard content and set it via JavaScript
    # This is more reliable than keyboard paste
    osascript <<EOF
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "
            var textarea = document.querySelector('textarea');
            if (textarea) { 
                textarea.focus(); 
                textarea.click();
            }
        "
    end tell
end tell
delay 0.3

tell application "System Events"
    tell process "Google Chrome"
        keystroke "v" using command down
    end tell
end tell
delay 0.5
EOF

    # Validate textarea has content
    textarea_chars=$(osascript <<'EOF'
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "document.querySelector('textarea').value.length"
    end tell
end tell
EOF
)
    
    if [ "$textarea_chars" -lt 100 ]; then
        echo "  ❌ FAILED: Keyboard paste failed ($textarea_chars chars in textarea)"
        return 1
    fi
    echo "  ✅ VALIDATED: Textarea has $textarea_chars chars"

    # Step 4: Click Clean Text button
    echo "  [5/6] Clicking Clean Text button..."
    osascript <<EOF
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
EOF
    echo "  ✅ Clicked Clean Text"

    # Close share modal if present
    osascript <<EOF
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
EOF

    # Step 5: Extract cleaned text via JavaScript
    echo "  [6/6] Extracting cleaned text..."
    cleaned_text=$(osascript <<EOF
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            // PROVEN: The cleaned text is in the second textarea
            var textareas = document.querySelectorAll('textarea');
            if (textareas.length > 1) {
                textareas[1].value;
            } else {
                '';
            }
        "
    end tell
end tell
EOF
)

    # Copy extracted text to clipboard using pbcopy
    if [ -n "$cleaned_text" ] && [ ${#cleaned_text} -gt 100 ]; then
        echo -n "$cleaned_text" | pbcopy
        echo "  ✅ VALIDATED: Cleaned text extracted (${#cleaned_text} chars)"
    else
        echo "  ❌ FAILED: Could not extract cleaned text (got ${#cleaned_text} chars)"
        return 1
    fi
}

# Function: Paste to LinkedIn
paste_to_linkedin() {
    local nav_result
    
    # Step 1: Navigate to LinkedIn
    echo "  [1/4] Navigating to LinkedIn..."
    nav_result=$(navigate_to_tab "linkedin.com")
    if [ "$nav_result" != "found" ]; then
        echo "  ❌ FAILED: Could not find LinkedIn tab"
        return 1
    fi
    echo "  ✅ VALIDATED: Found LinkedIn tab"
    sleep 0.8

    # Step 2: Scroll to top and click Start a post
    echo "  [2/4] Opening post dialog..."
    osascript <<EOF
tell application "Google Chrome"
    activate
end tell
delay 0.3

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
EOF
    echo "  ✅ Clicked Start a post"

    # Step 3: Focus the post editor (CRITICAL - must focus before pasting)
    echo "  [3/4] Focusing post editor..."
    osascript <<EOF
tell application "Google Chrome"
    activate
    delay 0.3
    tell active tab of front window
        execute javascript "
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
EOF
    echo "  ✅ Focused post editor"

    # Step 4: Paste content (Chrome must be active and editor focused)
    echo "  [4/4] Pasting content..."
    osascript <<EOF
tell application "System Events"
    tell process "Google Chrome"
        keystroke "v" using command down
    end tell
end tell
delay 1.0
EOF
    echo "  ✅ Pasted content to LinkedIn"
}

# Function: Schedule LinkedIn post
# PROVEN: Click clock icon, set date/time via input focus+select+type, click Next, click Schedule
schedule_linkedin_post() {
    local schedule_time="$1"
    local schedule_date="$2"

    # Step 1: Click clock icon via JavaScript
    echo "  [1/5] Clicking schedule icon..."
    osascript <<'EOF'
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                var ariaLabel = btns[i].getAttribute('aria-label') || '';
                if (ariaLabel === 'Schedule post' || ariaLabel.indexOf('Schedule') !== -1) {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
EOF
    sleep 1.5
    echo "  ✅ Schedule dialog opened"

    # Step 2: Set date (focus input, select, delete, type new date)
    # PROVEN: Must use select() + backspace + keystroke (not just select + keystroke)
    echo "  [2/5] Setting date to $schedule_date..."
    osascript <<EOF
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "
            var dateInput = document.querySelectorAll('input')[0];
            dateInput.focus();
            dateInput.select();
        "
    end tell
end tell
delay 0.2

tell application "System Events"
    tell process "Google Chrome"
        key code 51
        delay 0.2
        keystroke "$schedule_date"
    end tell
end tell
EOF
    sleep 0.3
    echo "  ✅ Date set"

    # Step 3: Set time (focus input, select, delete, type new time)
    # PROVEN: Must use select() + backspace + keystroke (not just select + keystroke)
    echo "  [3/5] Setting time to $schedule_time..."
    osascript <<EOF
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "
            var timeInput = document.querySelectorAll('input')[1];
            timeInput.focus();
            timeInput.select();
        "
    end tell
end tell
delay 0.2

tell application "System Events"
    tell process "Google Chrome"
        key code 51
        delay 0.2
        keystroke "$schedule_time"
    end tell
end tell
EOF
    sleep 0.3
    echo "  ✅ Time set"

    # Step 4: Click Next button
    echo "  [4/5] Clicking Next..."
    osascript <<'EOF'
tell application "Google Chrome"
    activate
    tell active tab of front window
        execute javascript "
            var btns = document.querySelectorAll('button');
            for (var i = 0; i < btns.length; i++) {
                if ((btns[i].innerText || '').trim() === 'Next') {
                    btns[i].click();
                    break;
                }
            }
        "
    end tell
end tell
EOF
    sleep 1
    echo "  ✅ Clicked Next"

    # Step 5: Click Schedule button to confirm
    echo "  [5/5] Clicking Schedule to confirm..."
    osascript <<'EOF'
tell application "Google Chrome"
    activate
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
EOF
    sleep 1
    echo "  ✅ Post scheduled for $schedule_date at $schedule_time"
}

# Function: Normalize Unicode title to plain text
normalize_title() {
    python3 "$SCRIPT_DIR/15-normalize-unicode-title.py" --extract-title <<< "$1"
}

# Function: Update Google Sheet
update_google_sheet() {
    local cell="$1"
    local content="$2"

    echo -n "$content" | pbcopy

    osascript <<EOF
-- Go to Google Sheets
tell application "Google Chrome"
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            if URL of t contains "docs.google.com/spreadsheets" then
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

-- Click name box and navigate to cell
tell application "Google Chrome"
    tell active tab of front window
        execute javascript "
            var nameBox = document.querySelector('#t-name-box');
            if (nameBox) { nameBox.click(); nameBox.focus(); }
        "
    end tell
end tell
delay 0.3

tell application "System Events"
    keystroke "$cell"
    key code 36
    delay 0.5
    keystroke "v" using command down
    delay 0.3
    key code 36
end tell
EOF
}

# Main execution
main() {
    local today_date="December 28, 2025"  # Tomorrow's date
    local sheet_row=275  # Row for 2025-12-28 (273 + 2)

    echo "==========================================="
    echo "LinkedIn Post Scheduler - 19-Step Workflow"
    echo "==========================================="
    echo "Schedule date: $today_date"
    echo ""
    
    # Step 0: Inspect Chrome window and validate tabs (MANDATORY FIRST STEP)
    init_chrome_window
    
    echo "Schedule times:"
    echo "  SOTA: 1:00 PM"
    echo "  AgenticAI: 2:00 PM"
    echo "  Cybersecurity: 3:00 PM"
    echo "  OpenSourceAIProjects: 4:00 PM"
    echo "  OpenSourceLLMs: 5:00 PM"
    echo ""

    declare -a titles

    for discipline in SOTA AgenticAI Cybersecurity OpenSourceAIProjects OpenSourceLLMs; do
        echo "==========================================="
        echo "Processing $discipline..."
        echo "==========================================="

        # 1. Clear clipboard
        pbcopy < /dev/null
        echo "  Cleared clipboard"

        # 2. Copy from ChatGPT
        copy_from_chatgpt "${GPT_IDS[$discipline]}"

        # Verify clipboard
        raw_content=$(pbpaste)
        char_count=${#raw_content}
        echo "  Copied from ChatGPT: $char_count characters"

        if [ $char_count -eq 0 ]; then
            echo "  ERROR: Failed to copy from ChatGPT"
            continue
        fi

        # 3. Clean content via Clean Paste (includes HITL)
        clean_via_cleanpaste

        # Verify cleaned content
        cleaned_content=$(pbpaste)
        cleaned_count=${#cleaned_content}
        echo "  Cleaned content: $cleaned_count characters"

        if [ $cleaned_count -gt 3000 ]; then
            echo "  WARNING: Content exceeds 3000 characters!"
        fi

        # 4. Extract and normalize title for later
        title=$(normalize_title "$raw_content")
        titles+=("$title")
        echo "  Title: $title"

        # 5. Paste to LinkedIn
        paste_to_linkedin
        echo "  Pasted to LinkedIn"

        # 6. Schedule on LinkedIn (includes HITL)
        schedule_linkedin_post "${SCHEDULE_TIMES[$discipline]}" "$today_date"
        echo "  Scheduled for ${SCHEDULE_TIMES[$discipline]}"

        echo ""
        sleep 1
    done

    echo "==========================================="
    echo "All posts scheduled!"
    echo "==========================================="
    echo ""
    echo "Now updating Google Sheet row $sheet_row..."

    # Update Google Sheet with titles
    idx=0
    for discipline in SOTA AgenticAI Cybersecurity OpenSourceAIProjects OpenSourceLLMs; do
        cell="${SHEET_COLUMNS[$discipline]}$sheet_row"
        echo "  Updating cell $cell with: ${titles[$idx]}"
        update_google_sheet "$cell" "${titles[$idx]}"
        ((idx++))
        sleep 1
    done

    echo ""
    echo "Done!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
