# Requirements

## Functional

- Scripts to: check prerequisites, open the Web Store page, launch Chrome with a dedicated profile, open extension settings, create a .env file, and verify the local endpoint.
- Store connection details in .env (host, port, token) read by scripts.
- Document required macOS permissions (Accessibility/Automation) for full control.
- Provide skills documentation for common automation patterns.

## MCP Tools Available

| Tool | Purpose |
|------|--------|
| `browser_navigate` | Navigate to a URL |
| `browser_snapshot` | Get accessibility tree with element refs |
| `browser_click` | Click element by ref |
| `browser_type` | Type text into element |
| `browser_wait` | Wait for specified seconds |
| `browser_screenshot` | Capture visual screenshot |
| `browser_hover` | Hover over element |
| `browser_select_option` | Select dropdown option |
| `browser_press_key` | Press keyboard key |
| `browser_go_back` | Navigate back |
| `browser_go_forward` | Navigate forward |
| `browser_get_console_logs` | Get browser console logs |

## Non-functional

- Local-only operations; no network calls or package installs by scripts.
- Idempotent scripts; safe to rerun.
- Clear manual steps for things that cannot be automated.
- Skills files use YAML-like pseudocode for clarity.
