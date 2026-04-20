---
name: search
description: >
  Guide for using Plex Search MCP tools — guide_agent for exploratory research and
  search_analyst for structured analysis. Covers tool selection, parameter tuning,
  compound similarity options, and multi-step workflows.
  Use when user asks "how do I search plex", "search for", "find compounds/targets/pathways",
  "analyze", or when helping a user decide which Plex search tool to use.
---

# Plex Search Tools

Plex provides two search tools via MCP. Choose based on the task.

## Tool Selection

### `guide_agent` — Exploratory Research

Use when the user wants to:
- Ask a natural language question ("What targets are associated with EGFR inhibitors?")
- Explore relationships without knowing exact entities
- Get a conversational summary with citations
- Discover unexpected connections

**Key behaviors:**
- Resolves entity names internally — no pre-resolution needed
- Runs iterative search loops (resolve → search → analyze)
- Long-running: 60–300 seconds typical
- Streams results in real-time

**Parameters:**
- `query` (required): natural language research question
- `ids` (optional): pre-resolved Plex IDs to constrain search
- `limit_categories` (optional): restrict to specific data categories

**Example calls:**
```
guide_agent(query="What are the known targets of imatinib and their associated pathways?")

guide_agent(query="Find compounds similar to aspirin with anti-inflammatory activity",
            limit_categories=["bioactivity"])
```

### `search_analyst` — Structured Analysis

Use when the user wants to:
- Analyze specific entities with evidence grounding
- Get structured output suitable for reports
- Examine pre-executed search results in depth
- Compare entities across datasets systematically

**Key behaviors:**
- Requires valid Plex IDs — use `resolve` first
- All IDs must be from the SAME category per call
- Long-running: 60–120 seconds typical
- Leads with most significant discovery, notes gaps

**Parameters:**
- `query` (required): description of what to analyze
- `ids` (optional): Plex IDs from resolve (required for precise searches)
- `sim_threshold` (optional): similarity cutoff, default 0.75 for compounds
- `sim_type` (optional): fingerprint type — `"sim"` (Tanimoto, default), `"ecfp4"` (Morgan/ECFP4, threshold ~0.30)
- `sim_limit` (optional): max similar compounds to return
- `limit_categories` (optional): restrict analysis to specific categories
- `find_related` (optional): discover related entities beyond direct matches

**Example calls:**
```
search_analyst(query="Analyze bioactivity profile of imatinib",
               ids=["COMPOUND:chembl941"],
               sim_type="sim", sim_threshold=0.75)

search_analyst(query="Compare target overlap between these kinase inhibitors",
               ids=["COMPOUND:chembl941", "COMPOUND:chembl1421"],
               limit_categories=["bioactivity", "target"])
```

## Common Workflows

### Compound Investigation
1. `resolve(terms=["imatinib"], category="compound")` → get Plex ID
2. `search_analyst(query="...", ids=[...], sim_type="sim")` → structured results

### Target Discovery
1. `guide_agent(query="What targets are implicated in Parkinson's disease?")` → exploratory
2. Pick specific targets from results
3. `resolve(terms=["LRRK2", "SNCA"], category="target")` → get IDs
4. `search_analyst(query="...", ids=[...])` → deep analysis

### Gene Set Analysis
1. `search_analyst(query="Analyze gene set", ids=[...list of gene IDs...])` → search gene set
2. Extract top 200 targets from results
3. `search_analyst(query="...", ids=[...top targets...])` → analyze those targets

## Similarity Search Tips

- **Tanimoto** (`sim_type="sim"`, threshold 0.75): broad structural similarity, good default
- **ECFP4** (`sim_type="ecfp4"`, threshold 0.30): Morgan fingerprints, more sensitive to substructure
- Set `sim_type=""` for exact compound match only (no similarity expansion)
- Lower thresholds return more results but with weaker structural relationships