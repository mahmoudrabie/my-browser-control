# my-browser-control

Chrome browser automation for macOS using AppleScript and Browser MCP.

## 🚀 Quick Start

### AppleScript Automation (Recommended)

**Use your actual Chrome profile with extensions and logins!**

```bash
# One-time: Enable JavaScript from Apple Events in Chrome
# View → Developer → Allow JavaScript from Apple Events ✓

# Run the automation
./scripts/applescript-full-automation.sh
```

### Browser MCP (Extension-Based)

For advanced features, set up the Browser MCP extension:

```bash
# Follow the step-by-step guide
cat spec/03-steps.md
```

## 📚 Documentation

### For AppleScript Automation

- **[Quick Reference](QUICK-REFERENCE.md)** - Command cheat sheet
- **[Automation Guide](scripts/APPLESCRIPT-AUTOMATION-GUIDE.md)** - Comprehensive patterns and examples
- **[Examples](scripts/examples/README.md)** - Working example scripts
- **[Skills: AppleScript](skills/07-applescript-automation.md)** - Core techniques

### For Browser MCP

- **[Requirements](spec/01-requirements.md)** - What you need
- **[Architecture](spec/02-architecture.md)** - How it works  
- **[Setup Steps](spec/03-steps.md)** - Installation guide
- **[Validation](spec/04-validation.md)** - Testing checklist

### Skills Documentation

- [Navigation](skills/01-navigation.md) - URL navigation patterns
- [Interaction](skills/02-interaction.md) - Clicking, typing, forms
- [Page Analysis](skills/03-page-analysis.md) - Reading page content
- [Workflows](skills/04-workflows.md) - Multi-step automation
- [Chrome Debug](skills/05-chrome-debug-mode.md) - Debug mode setup
- [MCP Comparison](skills/06-browser-mcp-comparison.md) - Tool comparison

## 🎯 Key Scripts

### Production-Ready Automation

```bash
# Main automation framework
./scripts/applescript-full-automation.sh [URL] [TEXT]

# LinkedIn posting workflow
./scripts/08-sota-posts-to-linkedin.sh

# Multi-tab manager
./scripts/examples/multi-tab-example.sh

# Text processor
./scripts/examples/text-processor-example.sh
```

### Setup Scripts

```bash
# Check prerequisites
./scripts/00-check-prereqs.sh

# Launch Chrome with debug mode
./scripts/02-launch-chrome-profile.sh

# Verify MCP port
./scripts/05-verify-port.sh
```

## ✨ Features

### AppleScript Automation
- ✅ Uses your actual Chrome profile
- ✅ Works with extensions and logins
- ✅ Tab management and switching
- ✅ No external dependencies (just Chrome)
- ✅ macOS native integration
- ✅ Safe text handling (UTF-8, special chars)
- ✅ Comprehensive error handling

### Browser MCP
- ✅ MCP protocol integration
- ✅ AI assistant compatibility
- ✅ Advanced element selection
- ✅ Network inspection
- ✅ Screenshot capabilities

## 🔧 Prerequisites

### For AppleScript
- macOS (any recent version)
- Google Chrome
- Python 3 (pre-installed on macOS)

### For Browser MCP
- All of the above, plus:
- Browser MCP Chrome extension
- MCP-compatible client (Claude Desktop, VS Code Copilot, etc.)

## 📖 Usage Examples

### Example 1: Basic Automation
```bash
./scripts/applescript-full-automation.sh \
    "https://cleanpaste.site" \
    "Text to clean"
```

### Example 2: Multi-Tab Workflow
```bash
# List tabs
./scripts/examples/multi-tab-example.sh list

# Copy from tab 2 to tab 5
./scripts/examples/multi-tab-example.sh copy 2 5
```

### Example 3: Batch Processing
```bash
./scripts/examples/text-processor-example.sh batch input.txt output.txt
```

### Example 4: LinkedIn Posting
```bash
# Extract from SOTA, clean, and post to LinkedIn
./scripts/08-sota-posts-to-linkedin.sh
```

## 🆚 When to Use What?

| Feature | AppleScript | Browser MCP |
|---------|-------------|-------------|
| Your Chrome profile | ✅ Yes | ✅ Yes |
| Extensions | ✅ Yes | ✅ Yes |
| Logged-in sessions | ✅ Yes | ✅ Yes |
| Tab switching | ✅ Yes | ⚠️ Limited |
| Setup complexity | ⭐ Simple | ⭐⭐ Moderate |
| AI integration | ❌ No | ✅ Yes |
| macOS only | ⚠️ Yes | ✅ Cross-platform |

**Use AppleScript for:** Simple automation, tab management, macOS-native workflows

**Use Browser MCP for:** AI-assisted browsing, complex element selection, cross-platform needs

## 🤝 Contributing

Contributions welcome! When adding new scripts:

1. Follow existing naming conventions
2. Include comprehensive help text
3. Add error handling
4. Update relevant documentation
5. Test on macOS with Chrome

## 📝 License

This is a personal project. Use at your own discretion.

## 🔗 Related Projects

- [Browser MCP Extension](https://github.com/browsermcp/mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Claude Desktop](https://claude.ai/desktop)

---

**Get Started:** Check out the [Quick Reference](QUICK-REFERENCE.md) or run your first script!

