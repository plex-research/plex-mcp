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
- Long-running: typically 5–30 minutes, but complex queries may run for hours
- Returns a **task stub immediately** — poll via `task_result(task_id=<taskId>)` every 30–60 seconds

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
- Long-running: typically 1–2 minutes, but complex queries may run longer
- Returns a **task stub immediately** — poll via `task_result(task_id=<taskId>)` every 30–60 seconds
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
               ids=["<imatinib Plex ID from resolve>"],
               sim_type="sim", sim_threshold=0.75)

search_analyst(query="Compare target overlap between these kinase inhibitors",
               ids=["<imatinib Plex ID>", "<dasatinib Plex ID>"],
               limit_categories=["bioactivity", "target"])
```

Plex IDs are whatever `resolve` returns for that entity (observed live: e.g. `unichem:161671`
for aspirin) — do not assume a fixed `COMPOUND:chemblNNN` scheme; always pull the `id` field
from the `resolve` response rather than constructing it.

## Polling Long-Running Tasks

`guide_agent` and `search_analyst` return a task stub — `{"taskId": ..., "status": "working"}` —
instead of blocking when a query doesn't complete within ~3 minutes.

- Poll with `task_result(task_id="...")`
- Poll at most once every 60 seconds — don't tight-loop
- If still `"working"` after 3 polls within the same turn, stop and tell the user to prompt
  again later rather than continuing to poll

## Presenting Results — Citation and Evidence Preservation

**Never summarize away citations, references, or evidence links from tool results.**

Plex results contain structured evidence that users depend on to verify findings and trace back to source data. When presenting results:

- **Preserve all citation IDs** (e.g. ChEMBL IDs, PubMed IDs, assay IDs, dataset references) exactly as returned — do not paraphrase or drop them
- **Keep evidence links intact** — if a result includes a URL, Plex entity ID, or external reference, include it verbatim in your response
- **Do not collapse multiple sources** into a vague summary ("several studies show...") — list each source cited by the tool
- **Attribute claims to their source** — if the tool returns "IC50 = 5 nM [ChEMBL assay CHEMBL123456]", present the assay ID alongside the value

**Wrong:**
> Imatinib shows strong BCR-ABL inhibition with nanomolar potency across several published assays.

**Right:**
> Imatinib inhibits BCR-ABL with IC50 = 2.1 nM (ChEMBL assay CHEMBL1614364) and 4.8 nM (ChEMBL assay CHEMBL1614365).

If the result set is large, summarize the pattern but still list the specific citations that support it — do not substitute a count ("12 assays") for the actual references unless the user explicitly asks for a summary only.

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