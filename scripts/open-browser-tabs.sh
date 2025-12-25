#!/bin/bash
# Open Chrome with existing profile and load tabs from bookmarks
# This uses AppleScript which preserves your logged-in profile

# Bookmarks from MyBrowserControl folder
URLS=(
    "https://cleanpaste.site"
    "https://web.whatsapp.com"
    "https://chatgpt.com"
    "https://docs.google.com/spreadsheets/d/1Hzz2XyEHIbaXIu4I8G3rwcnYDgP1K4dyXobelGoQ/edit"
    "https://www.textfixer.com/tools/remove-line-breaks.php"
)

# Activate Chrome (uses default profile)
osascript -e 'tell application "Google Chrome" to activate'
sleep 1

# Create window if none exists
osascript -e 'tell application "Google Chrome" to if (count of windows) = 0 then make new window'

# Open first URL in active tab
osascript -e "tell application \"Google Chrome\" to set URL of active tab of front window to \"${URLS[0]}\""

# Open remaining URLs in new tabs
for ((i=1; i<${#URLS[@]}; i++)); do
    osascript -e "tell application \"Google Chrome\" to tell front window to make new tab with properties {URL:\"${URLS[$i]}\"}"
done

echo "Opened ${#URLS[@]} tabs in Chrome with your profile"
