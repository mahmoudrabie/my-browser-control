#!/bin/bash
# Open Chrome in DEBUG mode with bookmarks from MyBrowserControl folder
# This allows full CDP MCP control but uses a separate profile

DATA_DIR="/Users/mahmoudrabie/MyAIProjects/my-browser-control/datadir"
BOOKMARKS_FILE="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"

# Quit existing Chrome gracefully
osascript -e 'quit app "Google Chrome"' 2>/dev/null
sleep 2

# Extract URLs from MyBrowserControl folder in bookmarks
URLS=$(python3 << 'EOF'
import json
import os

bookmarks_path = os.path.expanduser("~/Library/Application Support/Google/Chrome/Default/Bookmarks")

try:
    with open(bookmarks_path, 'r') as f:
        data = json.load(f)
    
    def find_folder(node, folder_name):
        if isinstance(node, dict):
            if node.get('name') == folder_name and node.get('type') == 'folder':
                return node
            for key, value in node.items():
                result = find_folder(value, folder_name)
                if result:
                    return result
        elif isinstance(node, list):
            for item in node:
                result = find_folder(item, folder_name)
                if result:
                    return result
        return None
    
    folder = find_folder(data, 'MyBrowserControl')
    
    if folder and 'children' in folder:
        urls = [child['url'] for child in folder['children'] if child.get('type') == 'url']
        print(' '.join(urls))
    else:
        print('')
except Exception as e:
    print('')
EOF
)

if [ -z "$URLS" ]; then
    echo "No bookmarks found in MyBrowserControl folder"
    URLS="about:blank"
fi

echo "Starting Chrome in DEBUG mode..."
echo "Data directory: $DATA_DIR"
echo ""

# Start Chrome with debugging enabled
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
    --remote-debugging-port=9222 \
    --user-data-dir="$DATA_DIR" \
    --no-first-run \
    --no-default-browser-check \
    $URLS &

sleep 3

echo ""
echo "Chrome is ready for CDP MCP control!"
echo ""
echo "Available commands:"
echo "  list_pages     - List all open tabs"
echo "  select_page    - Switch to a specific tab"
echo "  navigate_page  - Navigate current tab"
echo "  take_snapshot  - Get page elements"
echo "  click          - Click on element"
echo "  fill           - Type into input"
echo ""
echo "NOTE: This uses a separate profile. You may need to log in to sites."
