# Dune Table Schemas

Condensed schemas for all TON tables on Dune. Key columns and gotchas only.

## Core TON Tables

| File | Table | Description |
|------|-------|-------------|
| [accounts.md](accounts.md) | `ton.accounts` | Current state of all TON accounts |
| [messages.md](messages.md) | `ton.messages` | All messages (transactions) on TON |
| [balances.md](balances.md) | `ton.balances_history` + `ton.latest_balances` | Balance change-log and current snapshots |
| [jetton-events.md](jetton-events.md) | `ton.jetton_events` | Jetton (token) transfer events |
| [dex-trades.md](dex-trades.md) | `ton.dex_trades` | DEX swap data |
| [nft-events.md](nft-events.md) | `ton.nft_events` + `ton.nft_metadata` | NFT events and metadata |
| [prices-daily.md](prices-daily.md) | `ton.prices_daily` | Daily token prices (per raw unit) |

## TON Foundation Materialized Views — Quick Reference

Mat view docs are inlined in the schema files where they're most relevant. This table shows where to find each one.

| Mat View | Description | Source Query | Documented In |
|----------|-------------|-------------|---------------|
| `result_custodial_wallets` | CEX deposit wallets (~10.8M) | [Q5032986](https://dune.com/queries/5032986) | [accounts.md](accounts.md), [cex-flows.md](../../techniques/cex-flows.md) |
| `result_cex_flows_daily` | Daily CEX deposits/withdrawals (~38M) | TBD | [cex-flows.md](../../techniques/cex-flows.md) |
| `result_sybil_wallets` | Sybil/bot addresses (~153K) | [Q5206440](https://dune.com/queries/5206440) | [accounts.md](accounts.md) |
| `result_nominators_cashflow` | Staking deposit/withdrawal flows | TBD | [messages.md](messages.md) |
| `result_nominators_balances` | Current staking positions | TBD | [messages.md](messages.md) |
| `result_dex_pools_daily` | DEX pool metrics by day | TBD | [dex-trades.md](dex-trades.md) |
| `result_dex_pools_latest` | Current DEX pool state | TBD | [dex-trades.md](dex-trades.md) |
| `result_external_balances_history` | DeFi position changes | TBD | [balances.md](balances.md) |
| `result_jetton_price_daily` | Jetton prices | TBD | [prices-daily.md](prices-daily.md) |
| `dataset_labels` | Named entities (~3,150) | [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels) | [../../ton/labels.md](../../ton/labels.md) |
| `dune.rdmcd.result_gifts_collection_addresses` | 109 Telegram Gift collections | — | [../../ton/labels.md](../../ton/labels.md) |

### Gotchas
- `result_cex_flows_daily`: Safe for per-address CEX detection. WRONG for total market aggregation (inflates 2-3x). See [cex-flows.md](../../techniques/cex-flows.md).
- `result_custodial_wallets`: Contains ALL custodial wallets, not just CEX. Filter `WHERE category = 'CEX'`.
- `dataset_labels`: category is never NULL. Tags field contains special flags like `has-custodial-wallets`.
