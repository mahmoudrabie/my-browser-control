# Goals

- Automate browser interactions using AppleScript and System Events on macOS.
- Use existing Chrome windows and tabs - no new windows created during automation.
- Provide repeatable local scripts for LinkedIn post scheduling, content extraction, and Google Sheet updates.
- Document skills and patterns for effective browser automation using proven clipboard-based methods.
- Always start automation workflows by inspecting opened Chrome window tabs.

## Non-goals

- Remote control over the network.
- Bypassing macOS security.
- Opening new browser windows during automation workflows.
- Using MCP for browser control (replaced by AppleScript/System Events approach).

## Assumptions

- Google Chrome is installed and running with required tabs open.
- macOS Accessibility permissions granted to Terminal/VS Code for System Events.
- Required tabs already open: LinkedIn, Google Sheets, ChatGPT, Clean Paste (as needed).
- Single Chrome window with all required tabs.

## Key Learnings

- **Window Inspection First**: Always inspect opened Chrome window tabs before automation
- **Clipboard Method**: Use Cmd+A, Cmd+C for content extraction (JavaScript blocked on LinkedIn)
- **Dynamic Tab Detection**: Detect tab numbers by URL/title patterns, not hardcoded values
- **System Events**: Use AppleScript System Events for keyboard shortcuts and UI interactions
- **No New Windows**: Work with existing Chrome window, never create new windows

## Proven Automation Patterns

1. **inspect_chrome_window()** - Verify window exists, get tab count
2. **detect_required_tabs()** - Find tabs by URL pattern dynamically
3. **Clipboard extraction** - Cmd+A, Cmd+C for page content
4. **Python parsing** - Parse clipboard for structured data
5. **Google Sheets update** - Ctrl+G navigation, Escape+Delete clear, Cmd+V paste
