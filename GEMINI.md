# Plex Search MCP Tools

Connect to the Plex Search scientific research platform via MCP.

## Setup

Add Plex as an MCP server in your Gemini CLI config:
- Production: `https://plexsearch.com/mcp`
- Customer cell: `https://<cell>.plexsearch.com/mcp`

Authentication: API key via `x-api-key` header, or OAuth.

## Available Tools

### resolve
Convert entity names to Plex IDs. Required before `search_analyst`, optional before `guide_agent`.

- `terms`: array of names (gene symbols, compound names, SMILES, ChEMBL IDs)
- `category` (optional): `"compound"`, `"target"`, `"gwps"` (Perturb-Seq profiles), `"gds"` (RNA profiles)

Category notes:
- `gwps` returns perturbation profile records, not gene targets
- `gds` returns expression profile records, not gene targets

Match quality: `resolved-definitive` > `resolved` > `keyword` > `completion` > `fts`

### guide_agent
Exploratory research assistant. Accepts natural language queries, resolves entities internally, runs iterative search loops. Long-running: typically 5–30 minutes, but complex queries may run for hours. If it doesn't complete within ~3 minutes, returns a task stub instead of blocking — see `task_result`. In practice, `guide_agent` almost always returns a task stub on the first call — treat inline completion as the exception.

- `query`: natural language research question
- `ids` (optional): pre-resolved Plex IDs
- `limit_categories` (optional): restrict to specific data categories

### search_analyst
Structured analysis over pre-executed search results. Requires valid Plex IDs from `resolve`. All IDs must be same category. Long-running: typically 1–2 minutes, but complex queries may run longer. If it doesn't complete within ~3 minutes, returns a task stub instead of blocking — see `task_result`.

- `query`: what to analyze
- `ids`: Plex IDs from resolve
- `sim_threshold` (optional): similarity cutoff (default 0.75 for compounds)
- `sim_type` (optional): `"sim"` (Tanimoto) or `"ecfp4"` (Morgan, threshold ~0.30). Set `""` for exact only.
- `find_related` (optional): discover related entities beyond direct matches

### task_result
Poll for the result of a long-running `guide_agent` or `search_analyst` call that returned a task stub (`{"taskId": ..., "status": "working"}`).

- `task_id`: the `taskId` from the task stub
- Poll at most once every 60 seconds — don't tight-loop
- If still `"working"` after 3 polls within the same turn, stop and let the user know

## Workflows

**Exploratory**: `guide_agent(query="What targets are associated with EGFR inhibitors?")`

**Structured**: `resolve(terms=["imatinib"], category="compound")` → `search_analyst(query="...", ids=[...])`