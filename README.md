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

### Claude Science

1. **Settings → Connectors → Add connector → Remote**
2. **Name:** `plex-search`
3. **Server URL:** `https://plexsearch.com/mcp` (or `https://<cell>.plexsearch.com/mcp`)
4. **Advanced settings:**
   - **Transport:** `Streamable HTTP` — not SSE
   - **Headers helper command:** a command that outputs the auth header:
     ```bash
     echo "x-api-key: $PLEX_API_KEY"
     ```
     Set `PLEX_API_KEY` in your shell environment first, or read from a file:
     ```bash
     echo "x-api-key: $(cat ~/.config/plex-search/api-key)"
     ```
5. Save the connector and verify it shows as connected.

> **Why API key instead of OAuth?** OAuth tokens can fail to refresh after a Claude session sits idle — the API key header is regenerated fresh on each request, so there is no token to expire.

## MCP Tools

| Tool | Use for | Needs resolve first? |
|---|---|---|
| `guide_agent` | Exploratory natural language research questions | No (resolves internally) |
| `search_analyst` | Structured analysis with evidence grounding | Yes |
| `resolve` | Convert names/symbols/IDs to Plex IDs | — |
| `task_result` | Poll for the result of a long-running `guide_agent`/`search_analyst` call that returned a task stub — poll at most once per 60s | — |

> **Async task model:** `guide_agent` and `search_analyst` return a task stub immediately — `{"taskId": "...", "status": "working", "message": "..."}`. Call `task_result(task_id=<taskId>)` every 30–60 seconds to poll; after a few polls without completion, give the user the `taskId` and ask them to prompt again later.

## MCP Prompts

| Prompt | Description |
|---|---|
| `task_polling_instructions` | Explains the task stub / polling contract to the LLM client |

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

| Method | How |
|---|---|
| **API key** | Pass `x-api-key: <key>` header. Get a key: Account Settings → API Keys → Generate MCP key. |
| **OAuth** | No additional headers needed — handled by your MCP client. |

> **Recommendation for Claude Science:** use API key auth. OAuth tokens can silently fail to refresh after a session sits idle; the API key header is regenerated on every request.
