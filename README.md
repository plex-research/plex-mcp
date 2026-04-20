# Plex MCP

LLM tool plugins for the [Plex Search](https://plexsearch.com) scientific research platform.

## Quick Start

### Claude Code (plugin)

```bash
claude plugin marketplace add plex-research/plex-mcp && claude plugin install plex-search@plex-research
```

Then run `/plex-search:setup` to configure your MCP connection.

### Any tool (install script)

```bash
# macOS / Linux / WSL
bash <(curl -s https://raw.githubusercontent.com/plex-research/plex-mcp/main/hooks/install.sh)

# Windows PowerShell
irm https://raw.githubusercontent.com/plex-research/plex-mcp/main/hooks/install.ps1 | iex
```

Non-interactive:
```bash
bash <(curl -s https://raw.githubusercontent.com/plex-research/plex-mcp/main/hooks/install.sh) \
  --cell merck-kgaa --auth apikey --key YOUR_KEY
```

### Gemini CLI

```bash
gemini extensions install https://github.com/plex-research/plex-mcp
```

### ChatGPT

Settings → Connected Apps → add MCP server manually:
- URL: `https://plexsearch.com/mcp` (or `https://<cell>.plexsearch.com/mcp`)
- Type: HTTP

## MCP Tools

| Tool | Use for | Needs resolve first? |
|---|---|---|
| `guide_agent` | Exploratory natural language research questions | No (resolves internally) |
| `search_analyst` | Structured analysis with evidence grounding | Yes |
| `resolve` | Convert names/symbols/IDs to Plex IDs | — |

## Skills (Claude Code)

| Skill | Command | Description |
|---|---|---|
| **Setup** | `/plex-search:setup` | Configure MCP server connection |
| **Search** | `/plex-search:search` | Guide for `guide_agent` and `search_analyst` |
| **Resolve** | `/plex-search:resolve` | Entity resolution — names to Plex IDs |

## MCP Server URLs

| Deployment | URL |
|---|---|
| Production | `https://plexsearch.com/mcp` |
| Customer cell | `https://<cell>.plexsearch.com/mcp` |

## Authentication

- **API key**: `x-api-key` header
- **OAuth**: no additional headers needed