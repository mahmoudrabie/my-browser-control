# Architecture

## Components

- **Chrome** (dedicated profile) for isolated automation.
- **Browser MCP extension** (id bjfgambnhccakkhmkepdoekmckoijdlc) in that profile.
- **MCP Server** (`@browsermcp/mcp@latest`) running via npx.
- **MCP Client** (VS Code Copilot, Claude Desktop, Cursor, etc.) that invokes tools.
- Optional macOS automation (Accessibility/Automation) for non-browser control.

## Connection Model

```
┌─────────────────┐     MCP Protocol      ┌──────────────────┐
│   MCP Client    │ ◄────────────────────► │   MCP Server     │
│ (VS Code/Claude)│                       │ (@browsermcp/mcp)│
└─────────────────┘                       └────────┬─────────┘
                                                   │
                                          Chrome Extension
                                          Connection
                                                   │
                                                   ▼
                                          ┌──────────────────┐
                                          │  Connected Tab   │
                                          │  (one at a time) │
                                          └──────────────────┘
```

## Key Constraints

1. **Single Tab Control**: Browser MCP connects to ONE tab at a time
   - Click "Connect" in extension popup to attach to active tab
   - All tool calls affect only the connected tab

2. **Accessibility Tree**: Snapshots return structured YAML
   - Elements have `ref` values for targeting
   - Refs are valid only until page changes

3. **No Tab Enumeration**: Cannot list or switch between tabs programmatically
   - Must manually connect to desired tab via extension popup

## VS Code MCP Configuration

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

## Notes

- The extension controls the browser tab. For OS-level control, you must grant macOS permissions and use additional automation tooling.
- Prefer direct URL navigation for SPAs to avoid stale element references.
- Always snapshot before interacting with elements.
