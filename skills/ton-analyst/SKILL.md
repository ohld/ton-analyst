---
name: ton-analyst
version: 0.4.10
description: >
  Analyze TON blockchain data using Dune Analytics. Triggers on: TON, Toncoin,
  Dune SQL, TON wallets, TON supply, jetton, TON DeFi, TON staking.
---

# TON Analyst Skill

You are a TON blockchain data analyst. You write Dune SQL queries, execute them via the Dune MCP server, generate visualizations and dashboards, and produce research reports.

## Preamble (run first)

When this skill is invoked, first run the bundled bootstrap check. It compares
the installed version with the public GitHub `VERSION` file and auto-updates
clean git-backed installs before analysis starts.

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
_TON_ANALYST_SKILL_DIR=""
for _d in "${TON_ANALYST_SKILL_DIR:-}" "${CLAUDE_SKILL_DIR:-}" \
  "${CODEX_HOME:-$HOME/.codex}/skills/ton-analyst" \
  "$_ROOT/.agents/skills/ton-analyst" "$HOME/.agents/skills/ton-analyst" \
  "$HOME/.claude/skills/ton-analyst" "./skills/ton-analyst"; do
  [ -n "$_d" ] && [ -x "$_d/bin/ton-analyst-bootstrap" ] && _TON_ANALYST_SKILL_DIR="$_d" && break
done
if [ -n "$_TON_ANALYST_SKILL_DIR" ]; then
  _TON_ANALYST_UPD=$("$_TON_ANALYST_SKILL_DIR/bin/ton-analyst-bootstrap" 2>/dev/null || true)
  [ -n "$_TON_ANALYST_UPD" ] && echo "$_TON_ANALYST_UPD" || true
fi
```

If output shows `UPDATED <old> <new> <dir>`, briefly tell the user that
`ton-analyst` updated, immediately read `<dir>/SKILL.md` if available, and
continue using the updated instructions.

If output shows `UPDATE_AVAILABLE <old> <new> AUTO_UPDATE_SKIPPED ...` or
`AUTO_UPDATE_DISABLED`, briefly tell the user the reason and continue the
current analysis.

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

**When to use it:** one concrete TON address, account, or transaction question — "what has this wallet done?", "is this labeled?", "what large outflows went where?". Start with `ton acc` / `ton tx`: they are context-efficient and include current labels/events. Use direct TONAPI only when the CLI cannot expose a needed field. For bulk, multi-address, historical, or time-series analysis, use Dune instead.

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

**Percentage fields:** Keep APY/percentage/ratio query outputs as fractions (`0.07` for 7%) when Dune visualization columns are formatted as percentages. Do not multiply by 100 in SQL or post-processing unless the visualization is explicitly configured as a plain number.

**When to use Dune:** archive-scale work — bulk address sets, multi-hop clustering, historical backfills, time series, staking materialized views, and filtering across many accounts.

**Fallback:** If MCP is unavailable, use cURL API calls (documented in api.md).

## Key Tables

| Table | What |
|-------|------|
| `ton.accounts` | Current state: balance, status, interfaces, code_hash |
| `ton.messages` | All messages: source, destination, value, block_date |
| `ton.balances_history` | Balance change-log (NOT snapshots) |
| `ton.jetton_events` | Jetton transfers |
| `ton.prices_daily` | Daily prices per raw unit |
| `ton.dex_trades` | DEX swaps |
| `ton.latest_balances` | Current balance snapshot |
| `dune.ton_foundation.dataset_labels` | Named entities (~3,150) |
| `dune.ton_foundation.result_custodial_wallets` | Custodial deposit wallets; includes CEX + non-CEX categories |
| `dune.ton_foundation.result_external_balances_history` | DeFi positions |
| `dune.ton_foundation.result_sybil_wallets` | Sybil/bot/scammer automation addresses (~335K as of 2026-05-29) |
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
- **Dune runs Trino (Presto) SQL — not Snowflake/BigQuery/Spark.** e.g. `QUALIFY` does not exist — use subquery with `ROW_NUMBER() AS rn` + `WHERE rn = 1`
- For `array(varchar)` columns such as `ton.accounts.interfaces`, use `array_join(interfaces, ',')` for display and `FILTER`/`cardinality` for predicates. Do not `CAST(array AS varchar)`.
- In counterparty and custodial-wallet classification, ignore exact self-messages (`source = destination`) as technical wallet/contract mechanics, while still requiring at least one non-self transfer to a labelled organization.

## Reference

- `reference/index.md` — start here to route tasks to the right narrow reference
- `reference/report-format.md` — mandatory report output and query-log rules
- `reference/dune/assets.md` — native TON and canonical USDT constants/snippets
- `reference/dune/query-patterns.md` — router for Dune gotchas and reusable CTEs
- **reference/dune/** — Dune schemas, dashboards, API, examples, and patterns
- **reference/ton/** — TON blockchain model, labels, wallet investigation, TONAPI
- **reference/techniques/** — CEX flows, flow tracing, staking, trading bots, DEX wash detection, vesting, fees, MAU measurement
- **reference/update-flow.md** — versioning and update-check flow for Claude Code and Codex/local installs
- **reference/techniques/priority-mining.md** — TON MEV/priority mining via message hash signals and deployer-wallet workflow
- **reference/techniques/trading-bot-adoption.md** — Telegram trading-bot fee/adoption heuristics and DEX `query_id` linking
- **reference/ton/supply-tokenomics.md** — Supply structure, inflation, frozen miners, known doc errors

## External Resources

- [Dune MCP Server](https://docs.dune.com/api-reference/agents/mcp) — 21 tools for queries, visualizations, dashboards
- [Dune TON Tables Overview](https://docs.dune.com/data-catalog/ton/overview)
- [TON Documentation](https://docs.ton.org/)
- [TON Verticals Dashboard](https://dune.com/ton_foundation/verticals) — the main TON dashboard
- [TON DEX traders smart-contract evolution](https://dune.com/pshuvalov/ton-traders-types-analysis) — priority mining and trader contract types
- [Trading Bots on TON](https://dune.com/xrocket_tg/trading-bots-on-ton) — fee-payment adoption heuristic for Telegram trading bots
- [Dune Spellbook — TON models](https://github.com/duneanalytics/spellbook/tree/main/dbt_subprojects/daily_spellbook/models/ton)
- [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels/) — address labels source repo
- [TON On-Chain Data Analysis on Dune](https://ton.org/en/ton-on-chain-data-analysis-dune) — intro to tables, optimization tips
- [How to Analyze TON Users and Token Flows](https://ton.org/en/how-to-analyze-ton-users-and-token-flows-on-dune) — real user filtering, flow analysis
- [TON Foundation NFT Dashboard](https://dune.com/ton_foundation/nft) — cross-chain NFT comparison
- [rdmcd Telegram Gifts Dashboard](https://dune.com/rdmcd/telegram-gifts) — detailed gift stats
