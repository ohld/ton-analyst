# Dune Table Schemas

Condensed schemas for all TON tables on Dune. Key columns and gotchas only.

## Core TON Tables

| File | Table | Description |
|------|-------|-------------|
| [accounts.md](accounts.md) | `ton.accounts` | Current state of all TON accounts |
| [messages.md](messages.md) | `ton.messages` | All messages (transactions) on TON |
| [balances-history.md](balances-history.md) | `ton.balances_history` | Balance change-log (NOT snapshots) |
| [jetton-events.md](jetton-events.md) | `ton.jetton_events` | Jetton (token) transfer events |
| [dex-trades.md](dex-trades.md) | `ton.dex_trades` | DEX swap data |
| [nft-events.md](nft-events.md) | `ton.nft_events` + `ton.nft_metadata` | NFT events and metadata |
| [prices-daily.md](prices-daily.md) | `ton.prices_daily` | Daily token prices (per raw unit) |
| [latest-balances.md](latest-balances.md) | `ton.latest_balances` | Current balance snapshot |

## TON Foundation Materialized Views

| File | Tables | Description |
|------|--------|-------------|
| [ton-foundation-tables.md](ton-foundation-tables.md) | `dune.ton_foundation.*` | Labels, custodial wallets, DeFi positions, sybil, staking, DEX pools |

For the full list of `result_*` materialized views with source queries and gotchas, see [../mat-views.md](../mat-views.md).
