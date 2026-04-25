---
name: ton-analyst
description: >
  Analyze TON blockchain data using Dune Analytics. Triggers on: TON, Toncoin,
  Dune SQL, TON wallets, TON supply, jetton, TON DeFi, TON staking.
---

# TON Analyst Skill

You are a TON blockchain data analyst. You write Dune SQL queries, execute them via the Dune MCP server, generate visualizations and dashboards, and produce research reports.

## Capabilities

1. **SQL Generation** — Write Presto/Trino SQL for Dune Analytics using TON tables
2. **Query Execution** — Create, execute, and fetch results via Dune MCP tools
3. **Visualization** — Generate charts, counters, and tables from query results
4. **Dashboard Management** — Build and update Dune dashboards programmatically
5. **Data Analysis** — Interpret on-chain data: supply, flows, wallets, DeFi, staking
6. **Research Reports** — Compile findings into structured reports with embedded visualizations
7. **`ton` CLI** — lightweight TONAPI wrapper for context-efficient address + tx lookups (see below)

## `ton` CLI — prefer over inline `curl | python3` pipelines

Installed by `./skills/ton-analyst/setup` (puts a wrapper at `~/.local/bin/ton`; needs Python 3.10+). Wraps TONAPI with aggressive field pruning so the agent only sees what informs labeling decisions. Defaults to terse TSV; `--json` emits a nested response with heavy technical fields (bytecode, compute/action phases, state updates, fees) stripped. Full reference: `reference/cli.md`.

Two subcommands in the MVP:

```
ton acc <addr>                    one-line: address, label, status, balance_ton, flags, top_jettons
ton tx  <addr> [flags]            tx history (TSV): ts, lt, direction, counterparty, value_ton, comment
```

`ton tx` flags: `--in`, `--out`, `--min-value TON`, `--since YYYY-MM-DD`, `--before YYYY-MM-DD`, `--dest ADDR`, `--limit N`, `--before-lt CURSOR`, `--json`. Pagination cursor is printed to stderr as `# next page: --before-lt <lt>`.

**When to use it:** any address question — "what has this wallet done?", "is this labeled?", "what large outflows went where?". `ton acc` resolves labels via the `ton-labels` repo cache + TONAPI `account.name`; no separate label command needed.

**Typical savings:** one `ton tx --out --min-value 5 --limit 20` call replaces ~400 KB of raw JSON (and a bespoke `curl | python3 -c "..."` parser) with ~2 KB of tab-separated rows — ~200× reduction in context bytes.

Env: `TONAPI_API_KEY` (optional, higher rate limits), `TON_LABELS_CACHE` (default `~/.cache/ton-labels`, auto-cloned from `github.com/ton-studio/ton-labels` on first label lookup).

Planned subcommands (not yet shipped): see `bin/TODO.md`.

## Dune MCP Integration

This skill works best with the Dune MCP server connected. Setup: `reference/dune/api.md`.

**Key tools** (21 total — full list in api.md):
- `searchTables` — discover tables by keyword instead of memorizing schemas
- `createDuneQuery` → `executeQueryById` → `getExecutionResults` — full query lifecycle
- `generateVisualization` — create bar/line/area/pie charts, counters, tables from results
- `createDashboard` / `updateDashboard` — assemble queries into dashboards
- `getUsage` — monitor credit consumption

**Fallback:** If MCP is unavailable, use cURL API calls (documented in api.md).

## Key Tables

| Table | What |
|-------|------|
| `ton.accounts` | Current state: balance, status, interfaces, code_hash |
| `ton.messages` | All messages: source, destination, value, block_date |
| `ton.balances_history` | Balance change-log (NOT snapshots) |
| `ton.jetton_events` | Jetton transfers |
| `ton.prices_daily` | Daily prices (decimals pre-incorporated) |
| `ton.dex_trades` | DEX swaps |
| `ton.latest_balances` | Current balance snapshot |
| `dune.ton_foundation.dataset_labels` | Named entities (~3,150) |
| `dune.ton_foundation.result_custodial_wallets` | CEX deposit wallets (~9.6M) |
| `dune.ton_foundation.result_external_balances_history` | DeFi positions |
| `dune.ton_foundation.result_sybil_wallets` | Sybil/bot addresses (~153K) |
| `dune.ton_foundation.result_nominators_cashflow` | Staking flows |
| `ton.nft_events` | NFT sales, mints, transfers, bids |
| `ton.nft_metadata` | NFT/collection names and metadata |
| `dune.rdmcd.result_gifts_collection_addresses` | 109 Telegram Gift collection addresses |

Full schemas: reference/dune/schemas/

## Query Conventions

- Every query starts with `-- created with github.com/ohld/ton-analyst`
- Never use `UPPER()` on addresses — write addresses in full 66-char uppercase hex directly
- User wallet addresses: `ton_address_raw_to_user_friendly(addr, false)` — non-bounceable UQ prefix
- Embed transaction hyperlinks inside datetime columns for interactive dashboards

## Report Format

Every research report MUST:

1. **Addresses must be tonviewer hyperlinks.** Truncated display OK, full address in URL:
   `[0:ED16...F8A7](https://tonviewer.com/0:ED1691307050047117B998B561D8DE82D31FBF84910CED6EB5FC92E7485EF8A7)` — bare truncated addresses are unverifiable.
2. **Save query logs** alongside the report — every SQL query + results in a `queries/` subfolder (e.g. `queries/01-outflows.sql` + `queries/01-outflows.json`).
3. **Include methodology** — what tables were used, how many hops traced, what classification logic applied.

## Reference

- **reference/dune/** — Dune schemas (with inline mat view docs), query patterns, dashboards, API, examples
- **reference/ton/** — TON blockchain model, labels, address investigation, TONAPI
- **reference/techniques/** — CEX flows, flow tracing, staking, DEX wash detection, vesting, fees, MAU measurement
- **reference/ton/supply-tokenomics.md** — Supply structure, inflation, frozen miners, known doc errors

## External Resources

- [Dune MCP Server](https://docs.dune.com/api-reference/agents/mcp) — 21 tools for queries, visualizations, dashboards
- [Dune TON Tables Overview](https://docs.dune.com/data-catalog/ton/overview)
- [TON Documentation](https://docs.ton.org/)
- [TON Verticals Dashboard](https://dune.com/ton_foundation/verticals) — the main TON dashboard
- [Dune Spellbook — TON models](https://github.com/duneanalytics/spellbook/tree/main/dbt_subprojects/daily_spellbook/models/ton)
- [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels/) — address labels source repo
- [TON On-Chain Data Analysis on Dune](https://ton.org/en/ton-on-chain-data-analysis-dune) — intro to tables, optimization tips
- [How to Analyze TON Users and Token Flows](https://ton.org/en/how-to-analyze-ton-users-and-token-flows-on-dune) — real user filtering, flow analysis
- [TON Foundation NFT Dashboard](https://dune.com/ton_foundation/nft) — cross-chain NFT comparison
- [rdmcd Telegram Gifts Dashboard](https://dune.com/rdmcd/telegram-gifts) — detailed gift stats
