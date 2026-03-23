# codex-skill

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-skill-blue.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![Codex CLI](https://img.shields.io/badge/Codex_CLI-v0.115+-orange.svg)](https://github.com/openai/codex)
[![Context Cost](https://img.shields.io/badge/context_cost-~3K_tokens-brightgreen.svg)](#)

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill for delegating coding tasks to [OpenAI Codex CLI](https://github.com/openai/codex). Use presets for instant cost-controlled execution, or customize model, reasoning effort, and sandbox mode per task.

Type `/codex balanced fix the auth bug` and Claude hands it to Codex with the right flags. No manual flag juggling.

## Why use this?

Codex CLI is powerful but verbose. A simple task requires remembering model names, reasoning levels, sandbox modes, approval policies, and flag ordering. This skill wraps all of that into four presets and handles the edge cases (global flags before `exec`, `--full-auto` semantics, MCP config) so you don't have to.

## Installation

### Prerequisites

```bash
# 1. Install Codex CLI
npm i -g @openai/codex
# or: brew install --cask codex

# 2. Authenticate
codex login

# 3. Verify
codex --version
```

### Install the skill

```bash
# Global (available in all projects)
git clone https://github.com/b1rd33/codex-skill.git ~/.claude/skills/codex

# Project-level (current project only)
git clone https://github.com/b1rd33/codex-skill.git .claude/skills/codex
```

Done. Use `/codex` in Claude Code.

## Presets

| Preset | Effort | Use Case |
|--------|--------|----------|
| `turbo` | low | Typos, formatting, quick fixes |
| `balanced` | medium | Bug fixes, standard tasks (DEFAULT) |
| `quality` | high | Refactors, code review, security |
| `max` | xhigh | Architecture, critical decisions |

All presets use `gpt-5.4` with `workspace-write` sandbox, web search enabled, and `--full-auto` mode.

### What each preset runs

```bash
# turbo
codex --search exec -m gpt-5.4 -c model_reasoning_effort="low" --full-auto "task"

# balanced
codex --search exec -m gpt-5.4 -c model_reasoning_effort="medium" --full-auto "task"

# quality
codex --search exec -m gpt-5.4 -c model_reasoning_effort="high" --full-auto "task"

# max
codex --search exec -m gpt-5.4 -c model_reasoning_effort="xhigh" --full-auto "task"
```

## Usage examples

```
/codex turbo fix the typo in line 42
/codex balanced refactor this function to use async/await
/codex quality security audit the authentication module
/codex max redesign the database schema for scalability
/codex analyze this codebase  → asks for preset preference
```

### Task recommendations

| Task | Preset |
|------|--------|
| Typos, formatting | `turbo` |
| Bug fixes | `balanced` |
| Code review | `quality` |
| Security audit | `quality` or `max` |
| Architecture | `max` |
| Test generation | `balanced` |
| Documentation | `turbo` |

## Models

All models have 272K context. The skill defaults to `gpt-5.4`.

| Model | Best For |
|-------|----------|
| `gpt-5.4` | Flagship frontier, strongest reasoning (default) |
| `gpt-5.4-mini` | Smaller/cheaper frontier model |
| `gpt-5.3-codex` | Codex-optimized coding specialist |
| `gpt-5.2-codex` | Previous-gen coding model |
| `gpt-5.2` | Long-running agents |
| `gpt-5.1-codex-max` | Deep/fast reasoning |

Use `/model list` in Codex interactive mode to see all available models.

### Reasoning effort

| Level | When to use |
|-------|-------------|
| `low` | Simple, fast tasks |
| `medium` | Standard work (model default) |
| `high` | Complex analysis |
| `xhigh` | Critical, high-stakes decisions |

## MCP Server Setup

Codex can connect to external tools via MCP. Configure in `~/.codex/config.toml`:

```toml
# Notion (requires: codex mcp login notion)
[mcp_servers.notion]
url = "https://mcp.notion.com/mcp"

# Figma
[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"

# Context7 (docs lookup)
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
```

Manage servers:
```bash
codex mcp add <name> --url <url>           # Add HTTP server
codex mcp add <name> -- <command>          # Add STDIO server
codex mcp login <name>                     # OAuth authenticate
codex mcp list                             # List all servers
codex mcp remove <name>                    # Remove a server
```

## Advanced features

The skill also covers:
- **Web search** — `--search` global flag for live web access
- **Image input** — `-i screenshot.png` for visual context
- **Session management** — `codex resume --last`, `codex fork`
- **Cloud tasks** — `codex cloud exec` for remote execution
- **Code review** — `codex review --uncommitted`
- **Local models** — Ollama/LM Studio via `--oss`
- **Pipe input** — `git diff | codex exec --full-auto "review"`
- **Codex as MCP server** — `codex mcp-server` for multi-agent setups
- **Custom providers** — Azure, Mistral, custom endpoints

See [SKILL.md](SKILL.md) for full reference documentation.

## What's inside

```
codex-skill/
├── SKILL.md    # The skill file (loaded by Claude Code)
├── README.md   # This file
├── LICENSE     # MIT
└── .gitignore
```

Lean by design. The skill is a single file — no scripts, no dependencies, no build steps.

## Contributing

Found a bug? Want to improve the presets? PRs welcome.

- Verify CLI syntax against `codex --help` and `codex exec --help` before submitting
- Keep it lean — this is a reference skill, not a tutorial

## License

MIT — see [LICENSE](LICENSE).
