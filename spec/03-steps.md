# Steps

## Initial Setup

1. Run `scripts/00-check-prereqs.sh` to verify Chrome is installed.
2. Run `scripts/01-open-extension-page.sh` and install the Browser MCP extension.
3. Run `scripts/02-launch-chrome-profile.sh` to create the dedicated profile.
4. Run `scripts/03-open-extension-settings.sh` to access extension options.

## MCP Client Configuration

5. Add MCP server to your client:

   **VS Code (settings.json)**:
   ```json
   {
     "mcp": {
       "servers": {
         "browsermcp": {
           "command": "npx",
           "args": ["@browsermcp/mcp@latest"]
         }
       }
     }
   }
   ```

   **Claude Desktop (claude_desktop_config.json)**:
   ```json
   {
     "mcpServers": {
       "browsermcp": {
         "command": "npx",
         "args": ["@browsermcp/mcp@latest"]
       }
     }
   }
   ```

## Connecting to a Tab

6. Open the tab you want to control in Chrome.
7. Click the Browser MCP extension icon in Chrome toolbar.
8. Click **"Connect"** in the popup to attach to the current tab.
9. Verify connection status shows "Connected".

## Using Browser MCP

10. In your MCP client, verify tools are available:
    - `browser_navigate`
    - `browser_snapshot`
    - `browser_click`
    - `browser_type`
    - etc.

11. Basic usage pattern:
    ```
    1. browser_navigate → Go to URL
    2. browser_wait → Let page load
    3. browser_snapshot → Get element refs
    4. browser_click/type → Interact using refs
    ```

## Optional: OS-Level Permissions

12. Run `scripts/06-open-privacy-settings.sh` and grant Accessibility/Automation
    permissions to Chrome and your MCP client app if you need OS-level actions.

## Skills Reference

See `skills/` directory for detailed patterns:
- [01-navigation.md](../skills/01-navigation.md) - URL navigation
- [02-interaction.md](../skills/02-interaction.md) - Clicking, typing
- [03-page-analysis.md](../skills/03-page-analysis.md) - Reading pages
- [04-workflows.md](../skills/04-workflows.md) - Multi-step automation
