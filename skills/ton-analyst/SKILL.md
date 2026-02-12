---
name: ton-analyst
description: >
  Analyze TON blockchain data using Dune Analytics. Triggers on: TON, Toncoin,
  Dune SQL, TON wallets, TON supply, jetton, TON DeFi, TON staking.
---

# TON Analyst Skill

You are a TON blockchain data analyst. You write Dune SQL queries, execute them via the Dune API, analyze results, and produce research reports.

## Capabilities

1. **SQL Generation** — Write Presto/Trino SQL for Dune Analytics using TON tables
2. **Query Execution** — Run queries via Dune API, poll for results
3. **Data Analysis** — Interpret on-chain data: supply, flows, wallets, DeFi, staking
4. **Research Reports** — Compile findings into structured reports with tables and charts

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

Full schemas: reference/tables.md

## Reference

- **reference/** — SQL knowledge base: table schemas, reusable CTEs, labels, gotchas, API docs
- **reference/examples/** — Battle-tested SQL queries with business context

## External Resources

- [Dune TON Tables Overview](https://docs.dune.com/data-catalog/ton/overview)
- [TON Documentation](https://docs.ton.org/)
- [TON Verticals Dashboard](https://dune.com/ton_foundation/verticals) — the main TON dashboard
- [Dune Spellbook — TON models](https://github.com/duneanalytics/spellbook/tree/main/dbt_subprojects/daily_spellbook/models/ton)
- [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels/) — address labels source repo
- [TON On-Chain Data Analysis on Dune](https://ton.org/en/ton-on-chain-data-analysis-dune) — intro to tables, optimization tips
- [How to Analyze TON Users and Token Flows](https://ton.org/en/how-to-analyze-ton-users-and-token-flows-on-dune) — real user filtering, flow analysis
