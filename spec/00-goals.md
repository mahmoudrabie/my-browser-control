# Goals

- Use Browser MCP (`@browsermcp/mcp` / extension id bjfgambnhccakkhmkepdoekmckoijdlc) with a dedicated Chrome profile on macOS.
- Provide repeatable local scripts to install/open/configure and verify connectivity.
- Provide a clear runbook for connecting an MCP-capable client (VS Code, Claude Desktop, etc.).
- Keep the setup local and explicit about macOS permissions.
- Document skills and patterns for effective browser automation.

## Non-goals

- Remote control over the network or bypassing macOS security.
- Automating tasks outside of the browser without explicit OS permissions.
- Multi-tab or multi-window control (Browser MCP controls one connected tab at a time).

## Assumptions

- Google Chrome is installed.
- You will install the extension manually from the Chrome Web Store.
- The extension connects via the Chrome extension popup "Connect" button.
- MCP client (VS Code Copilot, Claude Desktop, etc.) is configured to use the browsermcp server.

## Key Learnings

- Browser MCP works by connecting to a **single tab** at a time
- Use `browser_snapshot` to get accessibility tree with element refs
- Use element `ref` values for reliable click/type targeting
- Prefer direct URL navigation over clicking for SPAs (avoids stale refs)
- Always wait after navigation before taking snapshots
