#!/usr/bin/env bash
set -euo pipefail

# Copy latest post from cyber_security_highlights tab and clean it in cleanpaste tab
# 
# PREREQUISITES:
# 1. Chrome: View → Developer → Allow JavaScript from Apple Events
# 2. Have both tabs open:
#    - cyber_security_highlights tab with posts
#    - cleanpaste.site tab
#
# USAGE:
#   ./copy-clean-security-post.sh

# ============================================================================
# Configuration
# ============================================================================

log() { 
  printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*" >&2
}

log_error() {
  printf "[%s] ERROR: %s\n" "$(date +%H:%M:%S)" "$*" >&2
}

log_success() {
  printf "[%s] ✓ %s\n" "$(date +%H:%M:%S)" "$*" >&2
}

# ============================================================================
# Main Script
# ============================================================================

main() {
  log "Starting cyber security post copy and clean workflow..."
  
  # Step 1: Find and switch to cyber_security_highlights tab
  log "Looking for cyber_security_highlights tab..."
  
  local cyber_tab_index
  cyber_tab_index=$(osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    if (count of windows) = 0 then error "No Chrome windows open"
    
    set win to front window
    set tabIndex to 0
    set foundIndex to 0
    
    repeat with t in (tabs of win)
        set tabIndex to tabIndex + 1
        set tabTitle to (title of t) as string
        set tabURL to (URL of t) as string
        
        -- Convert to lowercase for case-insensitive matching
        set lowerTitle to do shell script "echo " & quoted form of tabTitle & " | tr '[:upper:]' '[:lower:]'"
        set lowerURL to do shell script "echo " & quoted form of tabURL & " | tr '[:upper:]' '[:lower:]'"
        
        -- Check if tab contains "cyber" and "security" or "highlights"
        if (lowerTitle contains "cyber" and (lowerTitle contains "security" or lowerTitle contains "highlight")) or ¬
           (lowerURL contains "cyber" and lowerURL contains "security") then
            set foundIndex to tabIndex
            exit repeat
        end if
    end repeat
    
    if foundIndex = 0 then
        error "Could not find cyber_security_highlights tab"
    end if
    
    return foundIndex
end tell
APPLESCRIPT
  )
  
  if [ -z "$cyber_tab_index" ] || [ "$cyber_tab_index" = "0" ]; then
    log_error "Could not find cyber_security_highlights tab"
    exit 1
  fi
  
  log_success "Found cyber_security_highlights at tab $cyber_tab_index"
  
  # Step 2: Switch to cyber_security tab and extract latest post
  log "Extracting latest post from cyber_security_highlights..."
  
  local post_text
  post_text=$(osascript <<APPLESCRIPT
tell application "Google Chrome"
    set win to front window
    set active tab index of win to ${cyber_tab_index}
    delay 0.5
    
    -- JavaScript to extract the latest post (adjust selector as needed)
    set jsCode to "(() => {
        // Try multiple strategies to find the latest post
        
        // Strategy 1: Look for post containers (common patterns)
        let post = document.querySelector('.post:first-child, .article:first-child, article:first-child, [class*=\"post\"]:first-child');
        if (post) return post.innerText.trim();
        
        // Strategy 2: Look for specific data attributes
        post = document.querySelector('[data-post], [data-article]');
        if (post) return post.innerText.trim();
        
        // Strategy 3: Look for main content area
        let main = document.querySelector('main, #main, .main-content');
        if (main) {
            let firstPost = main.querySelector('div, article, section');
            if (firstPost) return firstPost.innerText.trim();
        }
        
        // Strategy 4: Get first substantial text block
        let textBlocks = Array.from(document.querySelectorAll('div, p, article')).filter(el => {
            return el.innerText && el.innerText.trim().length > 100;
        });
        
        if (textBlocks.length > 0) {
            return textBlocks[0].innerText.trim();
        }
        
        // Fallback: return page text
        return document.body.innerText.trim().substring(0, 5000);
    })()"
    
    set extractedText to execute active tab of win javascript jsCode
    
    if extractedText is missing value or extractedText = "" then
        error "Could not extract post text"
    end if
    
    return extractedText
end tell
APPLESCRIPT
  )
  
  if [ -z "$post_text" ]; then
    log_error "Could not extract post text from cyber_security_highlights tab"
    exit 1
  fi
  
  log_success "Extracted post (${#post_text} characters)"
  
  # Step 3: Find cleanpaste tab
  log "Looking for cleanpaste tab..."
  
  local clean_tab_index
  clean_tab_index=$(osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    set win to front window
    set tabIndex to 0
    set foundIndex to 0
    
    repeat with t in (tabs of win)
        set tabIndex to tabIndex + 1
        set tabTitle to (title of t) as string
        set tabURL to (URL of t) as string
        
        -- Check if tab contains "cleanpaste" or "clean paste"
        if tabTitle contains "cleanpaste" or ¬
           tabTitle contains "clean paste" or ¬
           tabURL contains "cleanpaste" then
            set foundIndex to tabIndex
            exit repeat
        end if
    end repeat
    
    if foundIndex = 0 then
        error "Could not find cleanpaste tab"
    end if
    
    return foundIndex
end tell
APPLESCRIPT
  )
  
  if [ -z "$clean_tab_index" ] || [ "$clean_tab_index" = "0" ]; then
    log_error "Could not find cleanpaste tab. Creating new tab..."
    
    # Create new cleanpaste tab
    osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    set win to front window
    tell win
        make new tab with properties {URL:"https://cleanpaste.site"}
    end tell
    delay 2
end tell
APPLESCRIPT
    
    # Find it again
    clean_tab_index=$(osascript <<'APPLESCRIPT'
tell application "Google Chrome"
    set win to front window
    return (count of tabs of win)
end tell
APPLESCRIPT
    )
  fi
  
  log_success "Found/created cleanpaste tab at index $clean_tab_index"
  
  # Step 4: Switch to cleanpaste tab and paste text
  log "Pasting text into cleanpaste and cleaning..."
  
  # Use Python for safe base64 encoding
  local encoded_text
  encoded_text=$(echo -n "$post_text" | python3 -c "import base64, sys; sys.stdout.write(base64.b64encode(sys.stdin.buffer.read()).decode('ascii'))")
  
  local result
  result=$(osascript - "$encoded_text" "$clean_tab_index" <<'APPLESCRIPT'
on base64Decode(b64String)
    return (do shell script "echo " & quoted form of b64String & " | base64 -d")
end base64Decode

on run argv
    set b64Text to item 1 of argv
    set tabIdx to item 2 of argv
    
    tell application "Google Chrome"
        set win to front window
        set active tab index of win to tabIdx
        delay 1
        
        -- Decode the text
        set decodedText to my base64Decode(b64Text)
        
        -- Step 1: Paste text
        set jsPaste to "
        (function() {
            var textarea = document.querySelector('textarea');
            if (!textarea) {
                textarea = document.querySelector('input[type=\"text\"]');
            }
            if (!textarea) {
                textarea = document.querySelector('[contenteditable=\"true\"]');
            }
            if (!textarea) {
                textarea = document.querySelector('input');
            }
            
            if (!textarea) {
                return JSON.stringify({ok: false, error: 'No input field found'});
            }
            
            textarea.value = '';
            textarea.focus();
            return JSON.stringify({ok: true, element: 'found'});
        })()
        "
        
        set checkResult to execute active tab of win javascript jsPaste
        
        -- Step 2: Set value using clipboard as workaround
        set the clipboard to decodedText
        delay 0.3
        
        set jsFillAndClick to "
        (function() {
            var textarea = document.querySelector('textarea');
            if (!textarea) textarea = document.querySelector('input[type=\"text\"]');
            if (!textarea) return JSON.stringify({ok: false, error: 'No textarea'});
            
            textarea.focus();
            textarea.select();
            document.execCommand('paste');
            
            setTimeout(function() {
                var cleanBtn = document.querySelector('button[type=\"submit\"]');
                if (!cleanBtn) {
                    var buttons = Array.from(document.querySelectorAll('button'));
                    cleanBtn = buttons.find(function(btn) {
                        var text = btn.innerText.toLowerCase();
                        return text.includes('clean') || text.includes('format') || text.includes('submit');
                    });
                }
                
                if (cleanBtn) {
                    cleanBtn.click();
                }
            }, 100);
            
            return JSON.stringify({ok: true, message: 'Text pasted'});
        })()
        "
        
        delay 0.5
        set result to execute active tab of win javascript jsFillAndClick
        return result
    end tell
end run
APPLESCRIPT
  )
  
  log_success "Completed!"
  echo "$result"
  
  # Step 5: Show final status
  log "Workflow completed successfully!"
  log "- Copied post from cyber_security_highlights tab"
  log "- Pasted into cleanpaste tab"
  log "- Triggered cleaning (if button was found)"
  
  log ""
  log "Check the cleanpaste tab for the cleaned result."
}

# Run main function
main "$@"
