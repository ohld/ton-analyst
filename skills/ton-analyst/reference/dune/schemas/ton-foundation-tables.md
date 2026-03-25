# dune.ton_foundation.* Tables

Materialized views and datasets maintained by TON Foundation. For the full list with source queries and gotchas, see [../mat-views.md](../mat-views.md).

## dune.ton_foundation.dataset_labels

Named entities on TON (~3,150 labels). Source: [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels).

| Column | Type | Notes |
|--------|------|-------|
| address | string | Raw format |
| label | string | e.g. `'Binance'`, `'frozen_early_miner'` |
| organization | string | Parent org |
| category | string | **Never NULL** — `'CEX'`, `'dex'`, `'bridge'`, etc. |
| subcategory | string | Finer classification |

Category breakdown and key labels: see [../../ton/labels.md](../../ton/labels.md).

## dune.ton_foundation.result_custodial_wallets

Custodial deposit wallets (~10.8M addresses). Details: see [../../ton/labels.md](../../ton/labels.md).

| Column | Type | Notes |
|--------|------|-------|
| address | string | |
| label | string | e.g. `'Binance | cust'`, `'wallet_in_telegram'` |
| category | string | `'CEX'` for exchanges, but also contains non-CEX wallets |

**WARNING:** This table contains MORE than CEX wallets. It includes Telegram-hosted wallets and other custodial services. When counting CEX deposits/volumes, always filter `WHERE category = 'CEX'`.

## dune.ton_foundation.result_external_balances_history

DeFi positions (lending, LP, farming). Change-log format.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | Partition key |
| address | string | User's wallet |
| asset | string | `'0:000...000'` for native TON (**NOT** `'TON'`!) |
| amount | decimal(38,0) | Balance after change |
| type | string | `'lending'`, `'dex'`, `'farming'` |
| project | string | `'evaa'`, `'tonco'`, `'ston.fi'` |
| pool_address | string | Specific pool contract |

## dune.ton_foundation.result_sybil_wallets

Sybil/bot addresses (~153K). Single column: `address`.

## dune.ton_foundation.result_nominators_cashflow

Staking flows for nominator pools.

| Column | Type | Notes |
|--------|------|-------|
| user_address | string | |
| value | bigint | Nanotons |
| direction | string | `'in'` (deposit) or `'out'` (withdrawal) |

## dune.rdmcd.result_gifts_collection_addresses

109 curated Telegram Gift collection addresses (maintained by @rdmcd).

| Column | Type | Notes |
|--------|------|-------|
| col_address | varchar | Collection address |
| nft_address | varchar | Example NFT item |
| item_name | varchar | e.g. 'Toy Bear' |
| collection_name | varchar | e.g. 'Toy Bears' |

## dune.telegram.stickers / dune.telegram.stickers_sales

Off-chain data uploaded by Telegram team.
- `stickers` — primary sales data (release_time, price, sold count)
- `stickers_sales` — marketplace sales (platform, block_time, amount_ton, amount_usd)

## Decoded project tables

Project-specific decoded tables exist in the Dune spellbook for EVAA, Affluent, StormTrade, and others. See [Dune Spellbook — TON](https://github.com/duneanalytics/spellbook/tree/main/dbt_subprojects/daily_spellbook/models/ton).
