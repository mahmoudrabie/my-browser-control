#!/bin/bash
# Open Chrome with existing profile and bookmarks from MyBrowserControl folder
# This script reads bookmarks from Chrome's profile and opens them

BOOKMARKS_FILE="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"

# Extract URLs from MyBrowserControl folder in bookmarks
# Using Python for reliable JSON parsing
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
    echo "Opening Chrome with default page..."
    open -a "Google Chrome"
else
    echo "Found bookmarks in MyBrowserControl folder"
    echo "Opening Chrome with these URLs..."
    
    # Open Chrome with all URLs (uses existing profile)
    open -a "Google Chrome" $URLS
fi

echo "Done! Chrome is open with your bookmarks."
echo ""
echo "To control with Browser MCP:"
echo "  1. Click Browser MCP extension icon on each tab"
echo "  2. Click 'Connect' to enable control"
echo ""
echo "To control with Chrome DevTools MCP (loses profile):"
echo "  Run: ./open-chrome-debug-with-bookmarks.sh"
