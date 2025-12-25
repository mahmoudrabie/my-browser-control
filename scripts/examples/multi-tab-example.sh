#!/usr/bin/env bash
# Example: Multi-Tab Workflow
# Demonstrates advanced tab management and cross-tab workflows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to list all Chrome tabs
list_chrome_tabs() {
    osascript <<'APPLESCRIPT'
on normalize(s)
    if s is missing value then return ""
    try
        return (s as string)
    on error
        return ""
    end try
end normalize

tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows"
    
    set output to ""
    set win to front window
    set tabIndex to 0
    set currentIndex to active tab index of win
    
    repeat with t in (tabs of win)
        set tabIndex to tabIndex + 1
        set tabTitle to my normalize(title of t)
        set tabURL to my normalize(URL of t)
        set marker to ""
        if tabIndex = currentIndex then
            set marker to " [ACTIVE]"
        end if
        set output to output & tabIndex & ". " & tabTitle & marker & "\n   " & tabURL & "\n\n"
    end repeat
    
    return output
end tell
APPLESCRIPT
}

# Function to switch to specific tab by index
switch_to_tab() {
    local tab_index="$1"
    osascript <<APPLESCRIPT
tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows"
    
    set win to front window
    set tabCount to count of tabs of win
    
    if ${tab_index} > tabCount or ${tab_index} < 1 then
        error "Invalid tab index: ${tab_index} (must be 1-" & tabCount & ")"
    end if
    
    set active tab index of win to ${tab_index}
    return "Switched to tab ${tab_index}"
end tell
APPLESCRIPT
}

# Function to get text from current tab
get_tab_text() {
    osascript <<'APPLESCRIPT'
on jsExtractText()
    return "(() => { const tas = document.querySelectorAll('textarea'); return tas.length > 1 ? (tas[1].value || tas[0].value || '') : (tas[0] ? tas[0].value : document.body.innerText.trim()); })()"
end jsExtractText

tell application "Google Chrome"
    set text to execute front window's active tab javascript (my jsExtractText())
    return text
end tell
APPLESCRIPT
}

# Function to get current tab info
get_current_tab_info() {
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows"
    
    set win to front window
    set currentTab to active tab of win
    
    set info to "Title: " & (title of currentTab) & "\n"
    set info to info & "URL: " & (URL of currentTab) & "\n"
    set info to info & "Tab: " & (active tab index of win) & " of " & (count of tabs of win)
    
    return info
end tell
APPLESCRIPT
}

# Function to create new tab
create_new_tab() {
    local url="${1:-about:blank}"
    osascript <<APPLESCRIPT
tell application "Google Chrome"
    if (count of windows) = 0 then
        make new window with properties {URL:"${url}"}
    else
        tell front window
            make new tab with properties {URL:"${url}"}
        end tell
    end if
    return "Created new tab: ${url}"
end tell
APPLESCRIPT
}

# Function to close current tab (with safety check)
close_current_tab() {
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows"
    
    set win to front window
    set tabCount to count of tabs of win
    
    if tabCount = 1 then
        error "Cannot close the last tab"
    end if
    
    close active tab of win
    return "Tab closed"
end tell
APPLESCRIPT
}

# Workflow: Copy from one tab to another
copy_between_tabs() {
    local source_tab="$1"
    local dest_tab="$2"
    
    echo "Switching to source tab #$source_tab..."
    switch_to_tab "$source_tab"
    sleep 0.5
    
    echo "Extracting text..."
    local text
    text=$(get_tab_text)
    
    echo "Text extracted: ${#text} characters"
    echo "First 100 chars: ${text:0:100}..."
    
    echo ""
    echo "Switching to destination tab #$dest_tab..."
    switch_to_tab "$dest_tab"
    sleep 0.5
    
    echo "Pasting text..."
    osascript <<APPLESCRIPT
on jsPasteText(text)
    set escaped to do shell script "python3 -c 'import sys, json; print(json.dumps(sys.argv[1]))' " & quoted form of text
    return "(() => { const text = " & escaped & "; const ta = document.querySelector('textarea') || document.querySelector('[contenteditable=\"true\"]'); if (ta) { if (ta.tagName === 'TEXTAREA') { ta.value = text; } else { ta.innerText = text; } ta.dispatchEvent(new Event('input', { bubbles: true })); return 'ok'; } return 'no-input'; })()"
end jsPasteText

tell application "Google Chrome"
    set result to execute front window's active tab javascript (my jsPasteText("${text}"))
    return result
end tell
APPLESCRIPT
    
    echo "Done!"
}

# Main interface
main() {
    case "${1:-help}" in
        list)
            echo "=== Chrome Tabs ==="
            list_chrome_tabs
            ;;
        switch)
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 switch TAB_NUMBER"
                exit 1
            fi
            switch_to_tab "$2"
            ;;
        info)
            echo "=== Current Tab Info ==="
            get_current_tab_info
            ;;
        text)
            echo "=== Current Tab Text ==="
            get_tab_text
            ;;
        new)
            create_new_tab "${2:-about:blank}"
            ;;
        close)
            close_current_tab
            ;;
        copy)
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                echo "Usage: $0 copy SOURCE_TAB DEST_TAB"
                exit 1
            fi
            copy_between_tabs "$2" "$3"
            ;;
        *)
            cat <<'HELP'
Multi-Tab Workflow Manager

USAGE:
  ./multi-tab-example.sh COMMAND [ARGS]

COMMANDS:
  list                  List all open Chrome tabs
  switch TAB_NUMBER     Switch to specific tab by number
  info                  Show current tab information
  text                  Extract text from current tab
  new [URL]             Create new tab (default: about:blank)
  close                 Close current tab (keeps at least one)
  copy SRC DEST         Copy text from source tab to destination tab

EXAMPLES:
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

WORKFLOW EXAMPLE:
  # List tabs to see what's available
  ./multi-tab-example.sh list
  
  # Switch to source tab
  ./multi-tab-example.sh switch 2
  
  # Verify content
  ./multi-tab-example.sh text | head -20
  
  # Copy to another tab
  ./multi-tab-example.sh copy 2 4

HELP
            ;;
    esac
}

main "$@"
