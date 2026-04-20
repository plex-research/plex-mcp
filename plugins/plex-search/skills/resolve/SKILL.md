---
name: resolve
description: >
  Guide for using the Plex resolve tool to convert entity names into Plex IDs.
  Covers category-specific behavior, match quality interpretation, and when resolution
  is required vs optional.
  Use when user asks "how do I resolve", "look up entity", "find plex ID for",
  or when helping prepare entities for search_analyst.
---

# Plex Entity Resolution

The `resolve` tool converts human-readable names (gene symbols, compound names, external IDs)
into Plex IDs needed by `search_analyst`.

## When to Use

- **Required** before `search_analyst` — it needs valid Plex IDs
- **Optional** before `guide_agent` — it resolves internally
- **Useful** to verify an entity exists in Plex before running a long search

## Parameters

- `terms` (required): array of names/identifiers to resolve
  ```
  resolve(terms=["imatinib", "aspirin", "CHEMBL941"])
  ```
- `category` (optional): constrain to a specific entity type
- `limit` (optional): max candidates per term, default 15

## Category-Specific Behavior

| Category | Accepts | Returns | Notes |
|---|---|---|---|
| `"compound"` | Names, SMILES, InChI, ChEMBL IDs | Compound records | Broadest input flexibility |
| `"target"` | Gene symbols, Entrez Gene IDs | Target records | Use official HGNC symbols |
| `"gwps"` | Gene symbols | **Perturbation profile** records | NOT gene targets — these are Perturb-Seq profiles |
| `"gds"` | Gene symbols | **Expression profile** records | NOT gene targets — these are RNA expression profiles |

### Critical: `gwps` and `gds` Categories

These return **profile records**, not the gene/target entities themselves. When a user asks
about gene perturbation data or RNA expression data, resolve against these categories to get
the correct profile IDs.

## Interpreting Results

Results include a `match_type` field indicating quality:

| Match Type | Meaning |
|---|---|
| `resolved-definitive` | Exact, unambiguous match — use confidently |
| `resolved` | Strong match, likely correct |
| `keyword` | Keyword-level match — review for relevance |
| `completion` | Prefix/autocomplete match — may be approximate |
| `fts` | Full-text search match — weakest, verify carefully |

**Best practice:** prefer `resolved-definitive` and `resolved` matches. If only `keyword`
or weaker matches return, the entity may not exist in Plex under that name — try alternate
names, synonyms, or external IDs.

## Examples

```
# Resolve a compound by name
resolve(terms=["imatinib"], category="compound")

# Resolve multiple targets by gene symbol
resolve(terms=["EGFR", "BRAF", "KRAS"], category="target")

# Resolve without category (searches all types)
resolve(terms=["aspirin"])

# Resolve a compound by SMILES
resolve(terms=["CC(=O)Oc1ccccc1C(=O)O"], category="compound")

# Resolve Perturb-Seq profiles for a gene
resolve(terms=["TP53"], category="gwps")
```

## Common Patterns

### Resolve → Search workflow
```
1. resolve(terms=["sorafenib"], category="compound")
   → returns id: "COMPOUND:chembl1336"

2. search_analyst(query="Analyze kinase selectivity of sorafenib",
                  ids=["COMPOUND:chembl1336"])
```

### Batch resolution
Resolve multiple entities in a single call rather than one at a time:
```
resolve(terms=["imatinib", "dasatinib", "nilotinib"], category="compound")
```
All IDs returned can then be passed together to `search_analyst` if they share the same category.