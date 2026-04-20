---
name: setup
description: >
  Configure the Plex Search MCP server in Claude Code. Walks through server URL,
  authentication method (API key or OAuth), and writes the mcpServers config entry.
  Use when user says "set up plex", "connect to plex", "configure plex mcp", or
  needs to add/change their Plex MCP connection.
---

# Plex Search MCP Setup

Configure Claude Code to connect to the Plex Search platform.

## Gather Information

Ask the user for:

1. **Cell name** (optional) — their organization's Plex cell name.
   - If provided: MCP URL is `https://<cell>.plexsearch.com/mcp`
   - If not provided (default production): `https://plexsearch.com/mcp`

2. **Authentication method** — how they authenticate with Plex:
   - **API key**: they have an `x-api-key` value to include as a header
   - **OAuth**: they use OAuth (no additional config needed in the MCP entry)

3. **Server name** — what to call this MCP entry in their config.
   - Default: `plex` (or `plex-<cell>` if cell-specific)

## Write Configuration

Add an entry to `~/.claude.json` under `mcpServers`:

### API key authentication

```json
{
  "mcpServers": {
    "plex": {
      "type": "http",
      "url": "https://plexsearch.com/mcp",
      "headers": {
        "x-api-key": "<their-api-key>"
      }
    }
  }
}
```

### OAuth authentication

```json
{
  "mcpServers": {
    "plex": {
      "type": "http",
      "url": "https://plexsearch.com/mcp"
    }
  }
}
```

## Verify Connection

After writing the config, tell the user to restart Claude Code, then test with:

```
Use the plex resolve tool to look up "aspirin"
```

If the resolve tool returns results, setup is complete.

## Cell-Specific Examples

| Organization | Cell | MCP URL |
|---|---|---|
| Default (production) | — | `https://plexsearch.com/mcp` |
| Acme Corp | `acme` | `https://acme.plexsearch.com/mcp` |
| Merck KGaA | `merck-kgaa` | `https://merck-kgaa.plexsearch.com/mcp` |

Replace with the customer's actual cell name. The cell name is provided during onboarding.