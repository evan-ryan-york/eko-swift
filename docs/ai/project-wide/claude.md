# Claude Code Configuration & MCP Servers

> **Last Updated**: January 2025
> **Purpose**: Document Claude Code setup, MCP servers, and when to use them

---

## Overview

This document describes the Claude Code configuration for the Eko project, including installed MCP (Model Context Protocol) servers and best practices for using them.

---

## Installed MCP Servers

### Context7 - Up-to-Date Documentation

**Purpose**: Fetch real-time, version-specific documentation for libraries and frameworks

**Installation Command**:
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
```

**When to Use**:
- ✅ When you need **current API documentation** for any library
- ✅ When checking **version-specific syntax** (e.g., Swift 6, iOS 17, Supabase v2.5.1)
- ✅ When implementing features with **unfamiliar APIs**
- ✅ To avoid **hallucinated or outdated** API calls

**Example Use Cases**:

1. **Swift & SwiftUI Documentation**
   ```
   User: "How do I use the new @Observable macro in Swift 6?"
   Claude: [Uses Context7 to fetch latest Swift 6 documentation]
   ```

2. **Supabase SDK Documentation**
   ```
   User: "What's the correct way to do real-time subscriptions in Supabase Swift SDK v2.5.1?"
   Claude: [Fetches Supabase Swift SDK v2.5.1 docs]
   ```

3. **OpenAI Realtime API**
   ```
   User: "Show me the latest OpenAI Realtime API WebRTC setup"
   Claude: [Gets current OpenAI Realtime API documentation]
   ```

4. **iOS Framework APIs**
   ```
   User: "How do I use AVAudioSession for recording in iOS 17?"
   Claude: [Fetches iOS 17 AVFoundation documentation]
   ```

**Supported Technologies** (Relevant to Eko):
- Swift & SwiftUI
- Supabase (JavaScript/TypeScript SDK - for Edge Functions)
- PostgreSQL
- OpenAI API
- WebRTC
- RevenueCat
- LiveKit
- Any npm or Swift package

**Benefits**:
- 🎯 **Accurate** - Real documentation from official sources
- 📅 **Current** - Always gets the latest version
- 🔍 **Specific** - Version-targeted examples
- 🚀 **Faster** - No need to manually search docs

---

### MUI Documentation (mui-mcp)

**Purpose**: Access Material-UI (MUI) component documentation

**Status**: Installed (available via `mcp__mui-mcp__useMuiDocs` and `mcp__mui-mcp__fetchDocs`)

**Relevance to Eko**: ❌ **Not applicable** - Eko is a native iOS app (Swift/SwiftUI), not a web app

**Note**: This MCP is installed but won't be used for this project since we don't use React or Material-UI. Consider removing if not needed for other projects.

---

## When AI Should Use MCP Servers

### Automatic Context7 Usage Triggers

AI agents working on Eko should **proactively use Context7** when:

1. **Implementing New Features**
   - Before writing code for unfamiliar APIs
   - When integrating new libraries or SDKs
   - When using new iOS framework features

2. **Debugging API Issues**
   - When API calls are failing unexpectedly
   - When method signatures seem incorrect
   - When response formats don't match expectations

3. **Upgrading Dependencies**
   - After updating Swift version
   - After updating Supabase SDK
   - After updating any major dependency

4. **User Asks "How Do I...?" Questions**
   - Questions about specific API usage
   - Questions about best practices for a library
   - Questions about configuration or setup

### Example Decision Flow

```
User asks: "How do I implement WebRTC in iOS?"
    ↓
AI Decision: This requires current API documentation
    ↓
Action: Use Context7 to fetch WebRTC iOS documentation
    ↓
Result: Provide accurate, up-to-date implementation guidance
```

```
User asks: "Update the OnboardingViewModel to add a new step"
    ↓
AI Decision: This is project-specific code, doesn't need external docs
    ↓
Action: Read existing code, follow golden-path.md patterns
    ↓
Result: Implement following existing architecture
```

---

## MCP Usage Best Practices

### DO Use Context7 For:

- ✅ Library API documentation
- ✅ Framework feature documentation
- ✅ SDK method signatures
- ✅ Configuration options
- ✅ Best practices from official sources
- ✅ Migration guides (e.g., Swift 5 → Swift 6)

### DON'T Use Context7 For:

- ❌ Project-specific code (use Read tool instead)
- ❌ Business logic questions (refer to architecture.md)
- ❌ Design patterns (refer to golden-path.md)
- ❌ Database schema (read migration files)
- ❌ Project configuration (read Config.swift, .xcodeproj)

---

## Configuration Files

### Local Project Config

**File**: `/Users/ryanyork/.claude.json` (project-specific)

**Contents** (MCP section):
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "mui-mcp": {
      "command": "npx",
      "args": ["-y", "@upstash/mui-mcp"]
    }
  }
}
```

### Verifying MCP Installation

```bash
# List all installed MCP servers
claude mcp list

# Expected output should include:
# - context7
# - mui-mcp
```

### Adding New MCP Servers

```bash
# General syntax
claude mcp add <name> <command> [args...]

# With double-dash for args
claude mcp add <name> -- <command> <args>

# With environment variables
claude mcp add <name> <command> -e KEY=value

# Examples:
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

### Removing MCP Servers

```bash
# Remove an MCP server
claude mcp remove <name>

# Example:
claude mcp remove chrome-devtools
```

---

## Recommended MCP Servers for iOS Development

### Currently Installed

1. **Context7** ✅ - Documentation fetching (essential)
2. **MUI MCP** ⚠️ - Not applicable to iOS project

### Consider Installing

1. **GitHub MCP**
   ```bash
   claude mcp add github -- npx -y @modelcontextprotocol/server-github
   ```
   **Use for**: Managing issues, PRs, releases

2. **PostgreSQL MCP** (if available)
   **Use for**: Direct database inspection, query optimization

3. **Filesystem MCP** (if needed beyond built-in tools)
   **Use for**: Advanced file operations

---

## Usage Examples

### Example 1: Fetching Supabase Documentation

```markdown
User: "How do I implement real-time subscriptions with Supabase Swift SDK?"

Claude Code:
1. Recognizes need for current API docs
2. Uses Context7: "Fetch Supabase Swift SDK documentation for real-time subscriptions"
3. Context7 returns latest official docs
4. Claude provides accurate code example using current API
```

### Example 2: Swift 6 Feature Usage

```markdown
User: "What's the proper way to use the new Observation framework?"

Claude Code:
1. Uses Context7: "Fetch Swift 6 Observation framework documentation"
2. Gets official Swift documentation
3. Provides example with @Observable, @MainActor, etc.
4. Shows modern patterns replacing old @ObservableObject
```

### Example 3: OpenAI Realtime API Integration

```markdown
User: "Help me integrate OpenAI Realtime API for voice mode"

Claude Code:
1. Uses Context7: "Fetch OpenAI Realtime API documentation"
2. Gets current WebRTC setup guide
3. Checks ephemeral token creation
4. Provides step-by-step implementation with current API endpoints
```

---

## AI Agent Instructions

### When Starting a Task

1. **Read Project Documentation First**
   - `docs/ai/project-wide/architecture.md` - Understand system design
   - `docs/ai/project-wide/golden-path.md` - Follow data flow patterns
   - `docs/ai/features/{feature}/feature-details.md` - Feature-specific context

2. **Determine If External Docs Needed**
   - Is this a new library integration? → Use Context7
   - Is this project-specific code? → Read existing code
   - Is this a known pattern? → Follow golden-path.md

3. **Use Context7 Proactively**
   - Don't wait for the user to ask "are you sure that's the right API?"
   - Fetch docs when you're not 100% certain about syntax
   - Validate your knowledge against current documentation

### Context7 Query Examples

**Good Queries** (specific, actionable):
```
"Supabase Swift SDK v2.5.1 authentication with OAuth"
"Swift 6 Observation framework @Observable macro usage"
"iOS 17 AVAudioSession recording configuration"
"OpenAI Realtime API WebRTC connection setup"
"PostgreSQL 17 JSONB GIN index performance"
```

**Bad Queries** (too vague):
```
"Swift programming"
"How to use Supabase"
"iOS development"
```

---

## Troubleshooting

### MCP Server Not Responding

**Symptoms**: Context7 not fetching docs, timeout errors

**Solutions**:
1. Check MCP server status: `claude mcp list`
2. Restart Claude Code
3. Reinstall MCP: `claude mcp remove context7 && claude mcp add context7 -- npx -y @upstash/context7-mcp@latest`
4. Check internet connection
5. Verify npx is installed: `npx --version`

### Outdated Documentation Returned

**Symptoms**: Context7 returns old API syntax

**Solutions**:
1. Be specific about version in query: "Supabase Swift SDK v2.5.1"
2. Force refresh by re-fetching
3. Check if library has updated recently (may take time to propagate)

### Rate Limiting

**Symptoms**: "Rate limit exceeded" errors

**Solutions**:
1. Get a free Context7 API key at https://context7.com/dashboard
2. Add API key to MCP config:
   ```bash
   claude mcp remove context7
   claude mcp add context7 -- npx -y @upstash/context7-mcp@latest --api-key YOUR_API_KEY
   ```

---

## Future Enhancements

### Potential MCP Servers to Add

1. **Supabase MCP** (if available)
   - Direct database inspection
   - Edge Function logs
   - Real-time monitoring

2. **GitHub MCP**
   - Issue tracking
   - PR management
   - Release automation

3. **Testing MCP** (if available)
   - XCTest result analysis
   - Code coverage reporting

### Configuration Improvements

1. **API Keys**: Add Context7 API key for higher rate limits
2. **Custom Prompts**: Create context7-specific prompts for common queries
3. **Caching**: Configure local caching for frequently accessed docs

---

## Related Documentation

- [Architecture](./architecture.md) - Complete system architecture
- [Golden Path](./golden-path.md) - Data flow best practices
- [Testing Strategy](./testing-strategy.md) - Testing approach
- [Project Overview](./project-overview.md) - Feature roadmap

---

## Quick Reference

### Common Commands

```bash
# List MCP servers
claude mcp list

# Add MCP server
claude mcp add <name> -- <command>

# Remove MCP server
claude mcp remove <name>

# Restart Claude Code (to reload MCP config)
# CMD+Q and relaunch, or restart terminal
```

### When to Use Context7

| Scenario | Use Context7? | Why |
|----------|---------------|-----|
| Implementing new Swift feature | ✅ Yes | Need current API docs |
| Following existing pattern | ❌ No | Use golden-path.md |
| Integrating new SDK | ✅ Yes | Need integration guide |
| Fixing project bug | ❌ No | Read project code |
| Upgrading dependencies | ✅ Yes | Check breaking changes |
| Writing tests | ⚠️ Maybe | Only if testing new APIs |

---

**Document Maintenance**: Update this document when adding/removing MCP servers or changing configuration. Last review: January 2025.
