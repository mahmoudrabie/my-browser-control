#!/usr/bin/env bash
set -euo pipefail

# LinkedIn Posts to Google Sheet Automation
#
# This script uses CLIPBOARD-BASED EXTRACTION (proven method):
# 1. Navigate to LinkedIn activity page
# 2. Use Cmd+A, Cmd+C to capture all visible content to clipboard
# 3. Parse clipboard with Python to extract posts, times, hashtags
# 4. Update Google Sheet with titles at correct date/discipline intersection
#
# WHY CLIPBOARD: JavaScript via AppleScript cannot access LinkedIn's
# dynamically loaded content (blocked by LinkedIn). Cmd+A/Cmd+C works.
#
# Usage:
#   ./17-linkedin-posts-to-sheet.sh START_DATE END_DATE
#   ./17-linkedin-posts-to-sheet.sh 2025-12-22 2025-12-26
#
# Prerequisites:
# - Chrome with LinkedIn activity page and Google Sheet tabs open
# - LinkedIn activity page: linkedin.com/in/YOUR_USER/recent-activity/all/

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Configuration
LINKEDIN_ACTIVITY_TAB="${LINKEDIN_ACTIVITY_TAB:-7}"
GOOGLE_SHEET_TAB="${GOOGLE_SHEET_TAB:-11}"
SHEET_START_DATE="2025-12-08"  # Row 237
SHEET_START_ROW=237
ROWS_PER_DATE=2  # Each date takes 2 rows in the sheet

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }
log_error() { printf "[%s] ERROR: %s\n" "$(date +%H:%M:%S)" "$*" >&2; }

# Validate date format
validate_date() {
    local date="$1"
    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_error "Invalid date format: $date (expected YYYY-MM-DD)"
        return 1
    fi
    return 0
}

# Calculate days between two dates
days_between() {
    local start="$1"
    local end="$2"
    python3 -c "
from datetime import datetime
d1 = datetime.strptime('$start', '%Y-%m-%d')
d2 = datetime.strptime('$end', '%Y-%m-%d')
print((d2 - d1).days)
"
}

# Navigate to tab
navigate_to_tab() {
    local tab_index="$1"
    osascript -e "tell application \"Google Chrome\" to activate" 
    sleep 0.3
    osascript -e "tell application \"Google Chrome\" to set active tab index of front window to $tab_index"
    sleep 0.5
}

# Refresh current tab
refresh_tab() {
    osascript -e 'tell application "System Events" to keystroke "r" using command down'
    sleep 2
}

# Scroll down in page
scroll_down() {
    osascript -e 'tell application "System Events" to key code 125 using command down'
    sleep 1
}

# Copy page content to clipboard using Cmd+A, Cmd+C (PROVEN METHOD)
copy_page_to_clipboard() {
    log "Copying page content to clipboard..."
    # Select all
    osascript -e 'tell application "System Events" to keystroke "a" using command down'
    sleep 0.5
    # Copy
    osascript -e 'tell application "System Events" to keystroke "c" using command down'
    sleep 0.5
}

# Parse clipboard content to extract posts using Python
parse_clipboard_posts() {
    local today="$1"
    local start_date="$2"
    local end_date="$3"
    
    python3 << 'PYPYTHON'
import sys
import re
import json
from datetime import datetime, timedelta

today_str = sys.argv[1] if len(sys.argv) > 1 else ""
start_date = sys.argv[2] if len(sys.argv) > 2 else ""
end_date = sys.argv[3] if len(sys.argv) > 3 else ""

# Read clipboard from stdin
clipboard = sys.stdin.read()

if not today_str:
    today = datetime.now()
else:
    today = datetime.strptime(today_str, '%Y-%m-%d')

def format_date(d):
    return d.strftime('%Y-%m-%d')

def relative_to_date(time_str):
    """Convert relative time (1h, 2d, 1w) to absolute date."""
    time_str = time_str.lower().strip()
    date = datetime(today.year, today.month, today.day)
    
    # Minutes or hours = today
    if re.match(r'^\d+m$', time_str) or re.match(r'^\d+h$', time_str):
        return format_date(date)
    
    # Days
    match = re.match(r'^(\d+)d$', time_str)
    if match:
        days = int(match.group(1))
        return format_date(date - timedelta(days=days))
    
    # Weeks
    match = re.match(r'^(\d+)w$', time_str)
    if match:
        weeks = int(match.group(1))
        return format_date(date - timedelta(weeks=weeks))
    
    # Months (approximate)
    match = re.match(r'^(\d+)mo$', time_str)
    if match:
        months = int(match.group(1))
        return format_date(date - timedelta(days=months*30))
    
    return None

def get_discipline(text):
    """Find discipline hashtag in text and return mapping."""
    mapping = {
        'for_solutions_architects': {'name': 'SOTA', 'column': 'B'},
        'for_ai_researchers': {'name': 'Agentic AI', 'column': 'C'},
        'cyber_security_highlights': {'name': 'Cybersecurity', 'column': 'D'},
        'open_source_ai_projects': {'name': 'Open Source AI Projects', 'column': 'E'},
        'open_source_llms': {'name': 'Open Source LLMs', 'column': 'F'}
    }
    
    text_lower = text.lower()
    for hashtag, info in mapping.items():
        # Match both #hashtag and hashtag#hashtag formats
        if hashtag in text_lower:
            return info
    return None

# Parse posts from clipboard
# LinkedIn clipboard format: "Feed post number X" followed by time like "1h • Edited •"
posts = []
lines = clipboard.split('\n')

# Time pattern: matches "1h •" or "2d •" or "1w •" at start of line
time_line_pattern = re.compile(r'^(\d+)(m|h|d|w|mo)\s*•')

# Also pattern for standalone time
time_standalone_pattern = re.compile(r'^(\d+)(m|h|d|w|mo)$')

i = 0
current_post_start = None
while i < len(lines):
    line = lines[i].strip()
    
    # Check if this line contains a time marker like "1h •" or "2d •"
    time_match = time_line_pattern.match(line)
    if time_match:
        time_str = time_match.group(1) + time_match.group(2)
        
        # Collect post content until next time marker or "Feed post number"
        post_lines = []
        j = i + 1
        while j < len(lines):
            next_line = lines[j].strip()
            if time_line_pattern.match(next_line):
                break
            if next_line.startswith('Feed post number'):
                break
            if next_line:
                post_lines.append(next_line)
            j += 1
        
        if post_lines:
            full_text = '\n'.join(post_lines)
            
            # Find first meaningful line (not hashtag line, not metadata)
            title = None
            for pl in post_lines:
                # Skip lines that are just hashtags
                if pl.startswith('hashtag#') and pl.count('hashtag#') > 2:
                    continue
                # Skip metadata lines
                if '• Edited •' in pl or 'Visible to anyone' in pl:
                    continue
                if len(pl) > 20:  # Real title should be substantial
                    title = pl
                    break
            
            if not title:
                title = post_lines[0]
            
            # Find discipline from hashtags in post
            discipline = get_discipline(full_text)
            post_date = relative_to_date(time_str)
            
            if discipline and post_date:
                # Filter by date range
                if start_date <= post_date <= end_date:
                    posts.append({
                        'title': title,
                        'date': post_date,
                        'column': discipline['column'],
                        'discipline': discipline['name'],
                        'timeText': time_str
                    })
        
        i = j
    else:
        i += 1

print(json.dumps(posts, indent=2))
PYPYTHON
}

# Main workflow
main() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 START_DATE END_DATE"
        echo "Example: $0 2025-12-22 2025-12-26"
        exit 1
    fi
    
    local start_date="$1"
    local end_date="$2"
    local today=$(date +%Y-%m-%d)
    
    validate_date "$start_date" || exit 1
    validate_date "$end_date" || exit 1
    
    log "==========================================="
    log "LinkedIn Posts to Google Sheet Automation"
    log "==========================================="
    log "Date range: $start_date to $end_date"
    log "Today: $today"
    log ""
    
    # Step 1: Navigate to LinkedIn activity tab
    log "Step 1: Navigate to LinkedIn activity tab ($LINKEDIN_ACTIVITY_TAB)"
    navigate_to_tab "$LINKEDIN_ACTIVITY_TAB"
    
    # Step 2: Refresh page
    log "Step 2: Refresh page"
    refresh_tab
    
    # Step 3: Scroll to load more posts
    local days_back=$(days_between "$start_date" "$today")
    local scroll_count=$((days_back / 3 + 2))  # ~3 days per scroll
    
    log "Step 3: Scroll to load posts ($scroll_count scrolls for $days_back days back)"
    for ((i=0; i<scroll_count; i++)); do
        scroll_down
    done
    sleep 2
    
    # Step 4: Copy page content to clipboard
    log "Step 4: Copy page content to clipboard (Cmd+A, Cmd+C)"
    copy_page_to_clipboard
    
    # Step 5: Parse clipboard for posts
    log "Step 5: Parse clipboard for posts in date range"
    local posts_json
    posts_json=$(pbpaste | python3 -c "
import sys
import re
import json
import unicodedata
from datetime import datetime, timedelta

today_str = '$today'
start_date = '$start_date'
end_date = '$end_date'

clipboard = sys.stdin.read()
today = datetime.strptime(today_str, '%Y-%m-%d')

# Unicode normalization mappings (fancy text to plain ASCII)
UNICODE_MAPPINGS = {
    range(0x1D400, 0x1D41A): lambda c: chr(ord('A') + (c - 0x1D400)),  # Bold A-Z
    range(0x1D41A, 0x1D434): lambda c: chr(ord('a') + (c - 0x1D41A)),  # Bold a-z
    range(0x1D434, 0x1D44E): lambda c: chr(ord('A') + (c - 0x1D434)),  # Italic A-Z
    range(0x1D44E, 0x1D468): lambda c: chr(ord('a') + (c - 0x1D44E)),  # Italic a-z
    range(0x1D468, 0x1D482): lambda c: chr(ord('A') + (c - 0x1D468)),  # Bold Italic A-Z
    range(0x1D482, 0x1D49C): lambda c: chr(ord('a') + (c - 0x1D482)),  # Bold Italic a-z
    range(0x1D63C, 0x1D656): lambda c: chr(ord('A') + (c - 0x1D63C)),  # Sans Bold Italic A-Z
    range(0x1D656, 0x1D670): lambda c: chr(ord('a') + (c - 0x1D656)),  # Sans Bold Italic a-z
    range(0x1D5D4, 0x1D5EE): lambda c: chr(ord('A') + (c - 0x1D5D4)),  # Sans Bold A-Z
    range(0x1D5EE, 0x1D608): lambda c: chr(ord('a') + (c - 0x1D5EE)),  # Sans Bold a-z
    range(0x1D670, 0x1D68A): lambda c: chr(ord('A') + (c - 0x1D670)),  # Monospace A-Z
    range(0x1D68A, 0x1D6A4): lambda c: chr(ord('a') + (c - 0x1D68A)),  # Monospace a-z
    range(0x1D7CE, 0x1D7D8): lambda c: chr(ord('0') + (c - 0x1D7CE)),  # Bold 0-9
    range(0x1D7EC, 0x1D7F6): lambda c: chr(ord('0') + (c - 0x1D7EC)),  # Sans Bold 0-9
}

def normalize_char(char):
    code = ord(char)
    for char_range, converter in UNICODE_MAPPINGS.items():
        if code in char_range:
            return converter(code)
    normalized = unicodedata.normalize('NFKD', char)
    ascii_char = normalized.encode('ascii', 'ignore').decode('ascii')
    return ascii_char if ascii_char else char

def strip_emojis(text):
    # Remove emojis and other non-ASCII symbols
    import re
    # Remove emojis (emoji ranges)
    emoji_pattern = re.compile('['
        '\U0001F600-\U0001F64F'  # emoticons
        '\U0001F300-\U0001F5FF'  # symbols & pictographs
        '\U0001F680-\U0001F6FF'  # transport & map symbols
        '\U0001F1E0-\U0001F1FF'  # flags
        '\U00002702-\U000027B0'  # dingbats
        '\U0001F900-\U0001F9FF'  # supplemental symbols
        '\U0001FA00-\U0001FA6F'  # chess symbols
        '\U0001FA70-\U0001FAFF'  # symbols extended
        '\U00002600-\U000026FF'  # misc symbols
        ']+', flags=re.UNICODE)
    return emoji_pattern.sub('', text).strip()

def normalize_title(text):
    # First normalize fancy unicode, then strip emojis
    normalized = ''.join(normalize_char(c) for c in text)
    return strip_emojis(normalized).strip()

def format_date(d):
    return d.strftime('%Y-%m-%d')

def relative_to_date(time_str):
    time_str = time_str.lower().strip()
    date = datetime(today.year, today.month, today.day)
    
    if re.match(r'^\d+m$', time_str) or re.match(r'^\d+h$', time_str):
        return format_date(date)
    
    match = re.match(r'^(\d+)d$', time_str)
    if match:
        return format_date(date - timedelta(days=int(match.group(1))))
    
    match = re.match(r'^(\d+)w$', time_str)
    if match:
        return format_date(date - timedelta(weeks=int(match.group(1))))
    
    match = re.match(r'^(\d+)mo$', time_str)
    if match:
        return format_date(date - timedelta(days=int(match.group(1))*30))
    
    return None

def get_discipline(text):
    mapping = {
        'for_solutions_architects': {'name': 'SOTA', 'column': 'B'},
        'for_ai_researchers': {'name': 'Agentic AI', 'column': 'C'},
        'cyber_security_highlights': {'name': 'Cybersecurity', 'column': 'D'},
        'open_source_ai_projects': {'name': 'Open Source AI Projects', 'column': 'E'},
        'open_source_llms': {'name': 'Open Source LLMs', 'column': 'F'}
    }
    
    text_lower = text.lower()
    for hashtag, info in mapping.items():
        if hashtag in text_lower:
            return info
    return None

posts = []
lines = clipboard.split('\n')
time_line_pattern = re.compile(r'^(\d+)(m|h|d|w|mo)\s*•')

i = 0
while i < len(lines):
    line = lines[i].strip()
    
    time_match = time_line_pattern.match(line)
    if time_match:
        time_str = time_match.group(1) + time_match.group(2)
        
        post_lines = []
        j = i + 1
        while j < len(lines):
            next_line = lines[j].strip()
            if time_line_pattern.match(next_line):
                break
            if next_line.startswith('Feed post number'):
                break
            if next_line:
                post_lines.append(next_line)
            j += 1
        
        if post_lines:
            full_text = '\n'.join(post_lines)
            
            title = None
            for pl in post_lines:
                if pl.startswith('hashtag#') and pl.count('hashtag#') > 2:
                    continue
                if '• Edited •' in pl or 'Visible to anyone' in pl:
                    continue
                if len(pl) > 20:
                    title = pl
                    break
            
            if not title:
                title = post_lines[0]
            
            # Normalize the title to plain ASCII (remove fancy Unicode formatting)
            title = normalize_title(title)
            
            discipline = get_discipline(full_text)
            post_date = relative_to_date(time_str)
            
            if discipline and post_date:
                if start_date <= post_date <= end_date:
                    posts.append({
                        'title': title,
                        'date': post_date,
                        'column': discipline['column'],
                        'discipline': discipline['name'],
                        'timeText': time_str
                    })
        
        i = j
    else:
        i += 1

print(json.dumps(posts, indent=2))
")
    
    # Save to temp file to avoid quoting issues
    local tmp_file
    tmp_file=$(mktemp)
    echo "$posts_json" > "$tmp_file"
    
    local post_count
    post_count=$(python3 -c "import json; print(len(json.load(open('$tmp_file'))))")
    
    log "Found $post_count posts in date range"
    
    if [[ "$post_count" -eq 0 ]]; then
        log "No posts found. Possible reasons:"
        log "  - Posts not loaded (try more scrolls)"
        log "  - Posts outside date range"
        log "  - Posts don't have recognized hashtags"
        log ""
        log "Debug: First 500 chars of clipboard:"
        pbpaste | head -c 500
        echo ""
        rm -f "$tmp_file"
        exit 0
    fi
    
    # Display found posts
    log ""
    log "Posts found:"
    python3 -c "
import json
posts = json.load(open('$tmp_file'))
for p in posts:
    print(f\"  [{p['date']}] {p['discipline']}: {p['title'][:50]}...\")
"
    log ""
    
    # Step 6: Navigate to Google Sheet
    log "Step 6: Navigate to Google Sheet tab ($GOOGLE_SHEET_TAB)"
    navigate_to_tab "$GOOGLE_SHEET_TAB"
    sleep 1
    
    # Step 7: Update cells
    log "Step 7: Update Google Sheet cells"
    
    python3 << PYPYTHON
import json
import subprocess
import sys
import time

posts = json.load(open('$tmp_file'))
sheet_start_date = "$SHEET_START_DATE"
sheet_start_row = $SHEET_START_ROW
rows_per_date = $ROWS_PER_DATE

from datetime import datetime

def date_to_row(target_date):
    d1 = datetime.strptime(sheet_start_date, '%Y-%m-%d')
    d2 = datetime.strptime(target_date, '%Y-%m-%d')
    days = (d2 - d1).days
    return sheet_start_row + (days * rows_per_date)  # Multiply by 2 since each date has 2 rows

def goto_cell(cell):
    # Ctrl+G to go to cell
    subprocess.run(['osascript', '-e', 
        'tell application "System Events" to keystroke "g" using control down'], 
        capture_output=True)
    time.sleep(0.5)
    
    subprocess.run(['osascript', '-e', 
        f'tell application "System Events" to keystroke "{cell}"'], 
        capture_output=True)
    time.sleep(0.2)
    
    subprocess.run(['osascript', '-e', 
        'tell application "System Events" to key code 36'], 
        capture_output=True)
    time.sleep(0.5)

def clear_and_type(text):
    # First ensure we're not in edit mode (Escape), then clear cell, then paste
    # Press Escape to exit any edit mode
    subprocess.run(['osascript', '-e', 
        'tell application "System Events" to key code 53'],  # Escape key
        capture_output=True)
    time.sleep(0.2)
    
    # Press Delete to clear cell content
    subprocess.run(['osascript', '-e', 
        'tell application "System Events" to key code 51'],  # Delete key
        capture_output=True)
    time.sleep(0.2)
    
    # Copy to clipboard then paste
    p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
    p.communicate(text.encode('utf-8'))
    
    subprocess.run(['osascript', '-e', 
        'tell application "System Events" to keystroke "v" using command down'], 
        capture_output=True)
    time.sleep(0.3)

def press_enter():
    subprocess.run(['osascript', '-e', 
        'tell application "System Events" to key code 36'], 
        capture_output=True)
    time.sleep(0.3)

for p in posts:
    row = date_to_row(p["date"])
    column = p["column"]
    title = p["title"]
    cell = f"{column}{row}"
    
    print(f"Updating {cell}: {title[:40]}...")
    
    goto_cell(cell)
    clear_and_type(title)
    press_enter()
    
    time.sleep(0.3)

print("Done!")
PYPYTHON
    
    # Cleanup
    rm -f "$tmp_file"
    
    log ""
    log "==========================================="
    log "Workflow complete!"
    log "==========================================="
}

main "$@"
