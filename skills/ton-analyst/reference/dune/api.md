# Dune API & Research Workflow

## API Key

Stored in `$DUNE_API_KEY` environment variable (from `~/.zshrc`). Never hardcode in files.

**All queries must be PRIVATE** (never public). Always add `LIMIT 50` to exploratory queries.

## Primary: Dune MCP (Preferred)

When the Dune MCP server is connected, use its tools directly — no cURL needed.

**Verified working end-to-end 2026-04-17:** `createDuneQuery`, `executeQueryById`, `getExecutionResults`, `generateVisualization` (counter), `updateDuneQuery` (SQL + name + tags — the legacy REST PATCH bug is fixed in the MCP path), `getDuneQuery`, `searchTables`, `getUsage`. Known broken: `listBlockchains` (404).

### Setup

```bash
# Claude Code (user scope, HTTP transport)
claude mcp add --scope user --transport http dune https://api.dune.com/mcp/v1 --header "x-dune-api-key: ${DUNE_API_KEY}"
```

Or in `.mcp.json`:
```json
{
  "dune": {
    "type": "http",
    "url": "https://api.dune.com/mcp/v1",
    "headers": { "x-dune-api-key": "${DUNE_API_KEY}" }
  }
}
```

### Available MCP Tools (21)

**Discovery** — find tables and docs without memorizing schemas:
| Tool | Use |
|------|-----|
| `searchDocs` | Search Dune documentation and SQL reference |
| `searchTables` | Find tables by keyword (e.g., "ton jetton") |
| `listBlockchains` | List supported blockchains — ⚠️ returns 404 as of 2026-04-17 (broken facet field); use `searchTables` with `blockchains: ["ton"]` instead |
| `searchTablesByContractAddress` | Find tables referencing a contract |
| `getTableSize` | Check table row count before querying |

**Query Lifecycle** — create, save, execute, get results:
| Tool | Use |
|------|-----|
| `createDuneQuery` | Create and save a new query (set `is_private: true`) |
| `getDuneQuery` | Fetch query SQL and metadata by ID |
| `updateDuneQuery` | Update existing query SQL/name/tags |
| `executeQueryById` | Execute a saved query |
| `getExecutionResults` | Fetch results of an execution |

**Visualization** — generate charts from query results:
| Tool | Use |
|------|-----|
| `generateVisualization` | Create chart, counter, or table from query results |
| `getVisualization` | Fetch existing visualization config |
| `updateVisualization` | Modify chart type, axes, colors |
| `deleteVisualization` | Remove a visualization |
| `listQueryVisualizations` | List all visualizations for a query |

**Dashboard** — build and manage dashboards:
| Tool | Use |
|------|-----|
| `createDashboard` | Create a new dashboard |
| `getDashboard` | Fetch dashboard layout and widgets |
| `updateDashboard` | Modify dashboard structure |
| `archiveDashboard` | Archive a dashboard |

**Account:**
| Tool | Use |
|------|-----|
| `getUsage` | Check credit usage and limits |

### MCP Workflow

1. **Write SQL** — follow patterns from query-patterns.md
2. **Create query** → `createDuneQuery` (always `is_private: true`)
3. **Execute** → `executeQueryById`
4. **Get results** → `getExecutionResults` (poll until complete)
5. **Visualize** → `generateVisualization` (chart, counter, or table)
6. **Dashboard** → `createDashboard` / `updateDashboard` to assemble views

### Visualization Types

Use `generateVisualization` after query execution to create:
- **Bar charts** — category comparisons, monthly volumes
- **Line charts** — time series, trends
- **Area charts** — cumulative flows, stacked breakdowns
- **Pie/donut** — distribution (holder types, categories)
- **Counters** — single KPI values (total supply, TVL)
- **Tables** — detailed data with clickable links

When configuring a visualization column as a percentage, the underlying query value must stay a ratio: `0.07` renders as `7%`. This applies to APY/APR/yield, share, rate, and other percent fields. Do not output `7` for `7%` unless the visualization is intentionally formatted as a plain number.

## Fallback: cURL API

If MCP is unavailable, use direct API calls.

### Execute Query

```bash
curl -X POST 'https://api.dune.com/api/v1/sql/execute' \
  -H "X-Dune-API-Key: ${DUNE_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT ... LIMIT 50", "is_private": true}'
```

Returns `execution_id`. Typical wait: 15-60s.

### Poll Results

```bash
curl "https://api.dune.com/api/v1/execution/${EXECUTION_ID}/results" \
  -H "X-Dune-API-Key: ${DUNE_API_KEY}"
```

Wait until `is_execution_finished: true` in the response.

### Dune CLI (for query updates)

```bash
dune query update <id> --sql "..." --name "..." --tags "x,y"
```

CLI works reliably for name/SQL updates; the REST API PATCH endpoint is broken for these fields.

## Rules

- **Always `is_private: true`** — never create public queries
- **Always `LIMIT 50`** for exploratory queries
- Don't multiply percentage ratios by 100 or divide TON by 1e6 — Dune UI handles display formatting. For percentage-formatted visualizations, `0.07` means `7%`, not `0.07%`.
- Check `getUsage` periodically to track credit consumption

## Research Workflow

1. **Understand the question** — What metric? What time range? What filters?
2. **Discover tables** — `searchTables` to find relevant data (or use schemas/ docs)
3. **Plan CTEs** — Start with LABELS/REAL_USERS if filtering users. Check query-patterns.md
4. **Write SQL** — Follow Presto/Trino syntax. Use `WHERE 1=1` + `AND` filters. Always filter `block_date` for partition pruning
5. **Create + Execute** — `createDuneQuery` → `executeQueryById` → `getExecutionResults`
6. **Visualize** — `generateVisualization` for charts/counters/tables
7. **Analyze results** — Look for outliers, compare with known facts
8. **Report** — Structure findings with tables, key takeaways, caveats
9. **Dashboard** — Optionally assemble into a dashboard with `createDashboard`
