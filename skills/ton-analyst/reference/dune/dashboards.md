# TON Foundation Dune Dashboards

Reference dashboards with battle-tested queries. Read their SQL before writing from scratch.

| Dashboard | URL | Key Queries |
|-----------|-----|-------------|
| TON Verticals | https://dune.com/ton_foundation/verticals | Main ecosystem overview |
| TON on CEX | https://dune.com/ton_foundation/ton-on-cex | CEX inflow/outflow, net flow, whale txs |
| Fragment | https://dune.com/ton_foundation/fragment | Buy/sell pressure, balance, revenue |
| NFT | https://dune.com/ton_foundation/nft | Cross-chain NFT comparison |
| Staking | https://dune.com/ton_foundation/staking | Staking flows, nominator pools, APY |
| TON Believers Fund | https://dune.com/ton_foundation/ton-believers-fund | Unlock tracking, destination analysis |

### How to Read Dashboard Queries

**Via MCP (preferred):**
- `getDuneQuery(queryId)` — fetch query SQL and metadata
- `getDashboard(dashboardId)` — fetch full dashboard layout and widget config (takes a numeric dashboard ID; slug input is not documented)
- `listQueryVisualizations(queryId)` — see all charts for a query

**Via CLI/API (fallback):**
```bash
curl -s "https://api.dune.com/api/v1/query/QUERY_ID" -H "X-Dune-API-Key: $DUNE_API_KEY" | jq -r '.query_sql'
```
Or via CLI: `dune query get QUERY_ID -o json | jq -r '.query_sql'`

### Managing Dashboards via MCP

- `createDashboard` — create new dashboard with title and description
- `updateDashboard` — add/remove widgets, reorder layout
- `archiveDashboard` — archive when no longer needed
- `generateVisualization` — add charts/counters to queries, then attach to dashboard
