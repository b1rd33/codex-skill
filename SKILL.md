---
name: codex
description: Delegate coding tasks to OpenAI Codex CLI. Supports presets (turbo/balanced/quality/max) or custom model+effort selection. Use when user wants to leverage GPT-5.4/Codex models for code analysis, refactoring, security audits, or complex transformations. Also covers MCP server management and advanced CLI features.
---

# OpenAI Codex CLI Integration

Delegate coding tasks to OpenAI's Codex CLI with flexible cost control.

## Quick Start

Usage: `/codex [preset] [task]` or `/codex [task]` (will ask for preferences)

## Presets (Cost-Optimized Shortcuts)

| Preset | Model | Effort | Use Case |
|--------|-------|--------|----------|
| `turbo` | gpt-5.4 | low | Near-instant tasks, typos, formatting |
| `balanced` | gpt-5.4 | medium | Standard tasks, bug fixes (DEFAULT) |
| `quality` | gpt-5.4 | high | Complex refactors, code review |
| `max` | gpt-5.4 | xhigh | Critical/architectural work |

All presets use `workspace-write` sandbox and `--full-auto` mode.

### Preset Commands

```bash
# turbo — fast, light reasoning
codex --search exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto "$ARGUMENTS"

# balanced — good default
codex --search exec -m gpt-5.4 -c model_reasoning_effort="medium" --full-auto "$ARGUMENTS"

# quality — deep analysis
codex --search exec -m gpt-5.4 -c model_reasoning_effort="high" --full-auto "$ARGUMENTS"

# max — highest capability
codex --search exec -m gpt-5.4 -c model_reasoning_effort="xhigh" --full-auto "$ARGUMENTS"
```

> **Note:** `--full-auto` sets `--sandbox workspace-write --ask-for-approval on-request`. Global flags like `--search` must come **before** `exec`.

---

## Custom Configuration (When No Preset Given)

If user doesn't specify a preset, ASK them to choose:

### 1. Model Selection

| Model | Best For | Notes |
|-------|----------|-------|
| `gpt-5.4` | Flagship frontier model, strongest reasoning + agentic workflows | Default, recommended |
| `gpt-5.4-mini` | Smaller frontier model, faster and cheaper | Good cost/quality tradeoff |
| `gpt-5.3-codex` | Frontier Codex-optimized agentic coding model | Coding specialist |
| `gpt-5.2-codex` | Frontier agentic coding model | Previous generation |
| `gpt-5.2` | Long-running agents and professional work | General purpose |
| `gpt-5.1-codex-max` | Deep and fast reasoning | Heavy computation |

> **Tip:** Run `/model list` during interactive sessions to see all available models.

### 2. Reasoning Effort

All current models default to `medium`. Supported levels vary by model.

| Level | Use Case | Speed/Cost |
|-------|----------|------------|
| `low` | Simple tasks, formatting | Fast/Cheap |
| `medium` | Standard work (DEFAULT) | Moderate |
| `high` | Complex analysis | Slow/High |
| `xhigh` | Critical decisions | Slowest/Highest |

> **Note:** `minimal` is only supported on `gpt-5`. Most models support `low|medium|high|xhigh`.

### 3. Sandbox Mode

| Mode | Use Case |
|------|----------|
| `read-only` | Analysis, review, docs |
| `workspace-write` | Code modifications (DEFAULT) |
| `danger-full-access` | System operations (rare) — also via `--yolo` |

### Custom Command Template

When using a sandbox other than `workspace-write`, use explicit flags instead of `--full-auto`:

```bash
codex exec \
  -m {model} \
  -c model_reasoning_effort="{effort}" \
  -a on-request \
  -s {sandbox} \
  "{task}"
```

For `workspace-write` with auto-approval, use `--full-auto`:

```bash
codex --search exec \
  -m {model} \
  -c model_reasoning_effort="{effort}" \
  --full-auto \
  "{task}"
```

---

## CLI Commands Reference

### Core Commands

| Command | Purpose |
|---------|---------|
| `codex` | Interactive TUI session |
| `codex exec` / `codex e` | Non-interactive execution |
| `codex review` | Non-interactive code review |
| `codex resume [SESSION_ID]` | Resume previous session (`--last` for most recent) |
| `codex fork [SESSION_ID]` | Fork/branch a previous session |
| `codex login` | Authenticate (OAuth, `--with-api-key`, or `--device-auth`) |
| `codex login status` | Check authentication status |
| `codex logout` | Remove stored credentials |
| `codex apply <TASK_ID>` | Apply a cloud task diff locally |
| `codex app` | Launch macOS desktop app |
| `codex completion [bash\|zsh\|fish]` | Generate shell completions |
| `codex features list` | Show feature flags and states |
| `codex features enable/disable` | Toggle feature flags |
| `codex sandbox` | Run commands in Codex sandbox (macOS/Linux/Windows) |
| `codex mcp-server` | Run Codex itself as an MCP server (stdio) |
| `codex cloud` | Remote cloud execution (experimental) |

### Cloud Tasks (Experimental)

```bash
codex cloud exec --env <ENV_ID> "task"    # Submit cloud task
codex cloud status <TASK_ID>              # Check task status
codex cloud list                          # List cloud tasks
codex cloud apply <TASK_ID>               # Apply diff locally
codex cloud diff <TASK_ID>                # View unified diff
```

---

## MCP Servers (Model Context Protocol)

MCP lets Codex connect to external tools and services — Notion, Figma, databases, docs, browsers, and more.

### Configuration

MCP config lives in `~/.codex/config.toml` (global) or `.codex/config.toml` (project-scoped, trusted projects only).

### Adding Servers

**Via CLI:**
```bash
# STDIO server (local process)
codex mcp add <server-name> --env VAR1=VALUE1 -- <command>

# HTTP server (remote)
codex mcp add <server-name> --url https://example.com/mcp

# With bearer token
codex mcp add <server-name> --url https://example.com/mcp --bearer-token-env-var MY_TOKEN
```

**Via config.toml directly:**

```toml
# STDIO server example
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[mcp_servers.context7.env]
MY_ENV_VAR = "value"

# HTTP server example
[mcp_servers.notion]
url = "https://mcp.notion.com/mcp"

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"

# Advanced HTTP with tool filtering
[mcp_servers.chrome_devtools]
url = "http://localhost:3000/mcp"
enabled_tools = ["open", "screenshot"]
startup_timeout_sec = 20
tool_timeout_sec = 60
```

### MCP Server Management Commands

```bash
codex mcp list              # List all configured servers
codex mcp list --json       # Machine-readable output
codex mcp get <name>        # Show specific server config
codex mcp get <name> --json # Machine-readable server config
codex mcp login <name>      # OAuth login for HTTP servers
codex mcp login <name> --scopes "scope1,scope2"  # With specific scopes
codex mcp logout <name>     # Remove OAuth credentials
codex mcp remove <name>     # Delete a server
```

### Using Notion via MCP

**Before first use, run this once to authenticate:**
```bash
codex mcp login notion
```
This opens a browser — authorize Codex to access your Notion workspace. Only needed once (credentials are cached).

**Config** (add to `~/.codex/config.toml`):
```toml
[mcp_servers.notion]
url = "https://mcp.notion.com/mcp"
```

**Usage examples:**
```bash
# Interactive
codex
> search my Notion for "project roadmap"
> create a new page in my Tasks database

# Non-interactive
codex exec -m gpt-5.4 --full-auto "list my recent Notion pages"
codex exec -m gpt-5.4 --full-auto "create a meeting notes page in Notion for today"
```

**If Notion tools aren't working:**
```bash
codex mcp list              # Check if notion is listed and connected
codex mcp login notion      # Re-authenticate if needed
/mcp                        # In interactive mode — verify notion tools are active
```

### Config Options Reference

| Option | Type | Description |
|--------|------|-------------|
| `command` | string | STDIO server startup command |
| `args` | array | Command arguments |
| `env` | table | Environment variables |
| `env_vars` | array | Env var names to pass through |
| `cwd` | string | Working directory for STDIO server |
| `url` | string | HTTP server address |
| `bearer_token_env_var` | string | Env var holding bearer token |
| `http_headers` | table | Static HTTP headers |
| `env_http_headers` | table | HTTP headers from env vars |
| `enabled_tools` | array | Whitelist specific tools |
| `disabled_tools` | array | Blacklist specific tools |
| `scopes` | array | OAuth scopes to request |
| `oauth_resource` | string | OAuth resource identifier |
| `startup_timeout_sec` | float | Server startup timeout (default: 10) |
| `tool_timeout_sec` | float | Tool call timeout (default: 60) |
| `enabled` | bool | Toggle server without deleting |
| `required` | bool | Fail startup if server unavailable |

### OAuth Configuration

```toml
# Fixed callback port (if provider requires it)
mcp_oauth_callback_port = 5555

# Custom callback URL
mcp_oauth_callback_url = "https://example.internal/callback"

# Credentials store
mcp_oauth_credentials_store = "auto"
```

### Popular MCP Servers

| Server | Type | Setup |
|--------|------|-------|
| Notion | HTTP | `url = "https://mcp.notion.com/mcp"` then `codex mcp login notion` |
| Figma | HTTP | `url = "https://mcp.figma.com/mcp"` + bearer token |
| Context7 | STDIO | `command = "npx"`, `args = ["-y", "@upstash/context7-mcp"]` |
| Playwright | STDIO | `command = "npx"`, `args = ["-y", "@anthropic/mcp-playwright"]` |
| OpenAI Docs | STDIO | `command = "npx"`, `args = ["-y", "@openai/docs-mcp"]` |
| Sentry | HTTP | URL + bearer token |

---

## Examples

```
/codex turbo fix the typo in line 42
/codex balanced refactor this function to use async/await
/codex quality security audit the authentication module
/codex max redesign the database schema for scalability
/codex analyze this codebase architecture  → (asks for preferences)
```

---

## Task-Specific Recommendations

| Task Type | Recommended Preset |
|-----------|-------------------|
| Typo/formatting fixes | `turbo` (low effort) |
| Quick bug fixes | `turbo` |
| Bug fixes | `balanced` |
| Code review | `balanced` or `quality` |
| Refactoring | `quality` |
| Security audit | `quality` or `max` |
| Architecture analysis | `max` |
| Documentation | `turbo` |
| Test generation | `balanced` |
| Migration/upgrade | `quality` or `max` |

---

## Advanced Features

### Web Search

Web search is a global flag that must come before `exec`:

```bash
# Enable web search (live)
codex --search exec -m gpt-5.4 --full-auto "use latest Next.js patterns for this route"
```

Or configure in `~/.codex/config.toml`:
```toml
web_search = "live"    # "disabled" | "cached" | "live"
```

### Image Attachments

```bash
# Single image
codex exec -i screenshot.png -m gpt-5.4 --full-auto "fix the UI layout issues shown here"

# Multiple images
codex exec -i design.jpg -i mockup.png -m gpt-5.4 --full-auto "implement this design"
```

### Session Management

```bash
codex resume --last               # Resume most recent session
codex resume <SESSION_ID>         # Resume specific session
codex exec resume --last          # Resume in non-interactive mode
codex fork --last                 # Fork most recent session
codex fork <SESSION_ID>           # Fork specific session
```

### Output Control

```bash
# Save final output to file
codex exec -o result.md -m gpt-5.4 --full-auto "analyze this codebase"

# JSON event stream
codex exec --json -m gpt-5.4 --full-auto "review this code"

# Structured output with schema
codex exec --output-schema schema.json -m gpt-5.4 --full-auto "extract API endpoints"

# Non-persisted session
codex exec --ephemeral -m gpt-5.4 --full-auto "quick analysis"
```

### Code Review

```bash
# Non-interactive (top-level command)
codex review                      # Review against default base
codex review --uncommitted        # Review staged + unstaged + untracked
codex review "focus on security"  # Custom review instructions

# In interactive mode
/review                           # Review uncommitted changes
/review main                      # Review diff against main branch
```

### Multi-Directory Access

```bash
codex exec --add-dir /path/to/shared-lib -m gpt-5.4 --full-auto "refactor using shared types"
```

### Local Models via Ollama

```bash
codex exec --oss -m mistral --full-auto "analyze this code"
codex exec --oss -m llama2 --full-auto "review for bugs"
```

Configure providers in `~/.codex/config.toml`:
```toml
oss_provider = "ollama"  # or "lmstudio"

[model_providers.ollama]
name = "Ollama"
base_url = "http://localhost:11434/v1"
```

### Profiles

```bash
# Use a named profile from config.toml
codex exec -p my-profile --full-auto "task"
```

### Pipe Input

```bash
cat file.py | codex exec -m gpt-5.4 --full-auto "review this code"
git diff | codex exec -m gpt-5.4 --full-auto "summarize changes"
```

### Codex as MCP Server

Run Codex itself as an MCP server for other agents (Claude Code, custom apps):

```bash
# Built-in command — exposes codex tools over stdio JSON-RPC
codex mcp-server
```

This lets external MCP clients invoke Codex as a tool — useful for multi-agent setups.

---

## Slash Commands (Interactive Mode)

| Command | Purpose |
|---------|---------|
| `/model` | Switch model or list available models |
| `/mcp` | List active MCP tools |
| `/review` | Analyze git diffs |
| `/diff` | Show git diff including untracked files |
| `/compact` | Summarize conversation to save tokens |
| `/permissions` | Set approval mode |
| `/plan` | Switch to plan mode |
| `/apps` | Browse available connectors/apps |
| `/agent` | Switch between agent threads |
| `/fork` | Clone conversation to new thread |
| `/new` | Fresh conversation in same session |
| `/copy` | Copy last Codex output |
| `/status` | Session config and token usage |
| `/skills` | List available skills |
| `/init` | Initialize project configuration |
| `/experimental` | Toggle experimental features |

---

## Other Configuration

```toml
# ~/.codex/config.toml

# Personality
personality = "pragmatic"    # "none" | "friendly" | "pragmatic"

# Service tier
service_tier = "fast"        # "flex" | "fast"

# Reasoning summary in responses
model_reasoning_summary = "concise"  # "auto" | "concise" | "detailed" | "none"

# History persistence
[history]
persistence = "save-all"     # "save-all" | "none"

# Shell environment
[shell_environment_policy]
inherit = "all"              # "all" | "core" | "none"

# Multi-agent
[features]
multi_agent = true           # Enable subagent spawning
web_search = true            # Enable web search
fast_mode = true             # Enable fast mode
```

---

## Debugging & Troubleshooting

```bash
# Debug mode — see full output without auto-approval
codex exec -m gpt-5.4 -c model_reasoning_effort="medium" -a untrusted -s workspace-write "your task"

# Check health
codex --version
codex --help
codex login status

# List feature flags
codex features list

# CI-friendly output (no alternate screen)
codex --no-alt-screen exec --full-auto "task"
```

| Issue | Solution |
|-------|----------|
| "Model not found" | `/model list` in interactive mode |
| "Authentication failed" | `codex login` or `codex login --with-api-key` |
| "Permission denied" | Check sandbox mode — try `workspace-write` |
| Slow response | Lower reasoning effort or use `turbo` preset |
| No output | Use `codex` (interactive) instead of `codex exec` |
| MCP server won't connect | Check `codex mcp list`, try `codex mcp login <name>` |
| MCP tools not showing | Type `/mcp` in TUI to verify active tools |

---

## Prerequisites

1. Codex CLI installed: `npm i -g @openai/codex` or `brew install --cask codex`
2. Authenticated: Run `codex login` and follow prompts (or `codex login --with-api-key` for CI)
3. Verify: `codex --version`
4. MCP servers (optional): Configure in `~/.codex/config.toml`, authenticate with `codex mcp login <name>`
