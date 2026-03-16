# Table Schemas

Condensed schemas for all TON tables on Dune. Key columns and gotchas only.

## ton.accounts

Current state of all TON accounts.

| Column | Type | Notes |
|--------|------|-------|
| address | string | Raw format (`0:...` or `-1:...`) |
| interfaces | array(string) | Prepopulated by Dune from known `code_hash` → interface mappings (e.g. `jetton_wallet`, `wallet_v4r2`, `nft_item`). Not all contracts are decoded — use `code_hash` directly for uncommon types. |
| balance | bigint | Current balance in nanoTON (divide by 1e9) |
| status | string | `active`, `uninit`, `nonexist`, `frozen` |
| deployment_at | timestamp | When account was deployed |
| last_tx_at | timestamp | Last transaction time |
| first_tx_sender | string | Address that initiated first tx to this account |
| code_hash | string | Base64-encoded contract code hash |

**Status gotcha:** Early miners = `status='uninit'` (NOT `frozen`). The `frozen` status has only 31 addresses with ~0 TON.

**Known wallet interfaces:** `wallet_v3r2`, `wallet_v4r2`, `wallet_v5r1`, `wallet_highload_v3r1` (high-throughput, used by some CEXes — but NOT a CEX indicator on its own).

**Interface patterns:**
```sql
-- Is wallet?
cardinality(FILTER(interfaces, i -> regexp_like(i, '^wallet_'))) > 0
-- Is multisig?
cardinality(FILTER(interfaces, i -> regexp_like(i, '^multisig'))) > 0
-- Is nominator pool? (catches masterchain + basechain)
cardinality(FILTER(interfaces, i -> i = 'validation_nominator_pool')) > 0
-- Exclude jetton wallets
array_position(A.interfaces, 'jetton_wallet') = 0
```

## ton.messages

All messages (transactions) on TON.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | **Partition key** — always filter for pruning |
| block_time | timestamp | Use for `date_trunc('hour', ...)`. Use `block_date` for range filters |
| tx_hash | string | |
| trace_id | string | |
| direction | string | `'in'` or `'out'` |
| source | string | Raw address |
| destination | string | Raw address |
| value | bigint | Nanotons (divide by 1e9) |
| opcode | int | 260734629 = jetton internal transfer |
| bounced | boolean | Filter with `NOT bounced` |
| comment | string | Human-readable comment |
| fwd_fee | bigint | Forward fee |

**CRITICAL — always filter `direction = 'in'` when aggregating.** TON uses async message-passing: a transaction has 1 incoming message and may produce outgoing messages that trigger further transactions (all sharing the same `trace_id`). The `ton.messages` table stores both `direction='in'` and `direction='out'` rows. Without filtering, SUMs and COUNTs will be inflated. See reference/ton-blockchain.md for the full execution model.

**Standard filter:** `WHERE direction = 'in' AND NOT bounced AND block_date >= DATE '...'`

## ton.balances_history

Records every **change** in balance. Change-log format, NOT snapshots.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | **Partition key** |
| block_time | timestamp | |
| address | string | Raw format |
| asset | string | `'TON'` for native, jetton_master address for jettons |
| amount | decimal(38,0) | Balance AFTER the change (raw units) |

**Critical:** No row = no change that day. Use `MAX_BY(amount, block_date)` for snapshots. See patterns.md for forward-fill.

**Asset naming gotcha:** Native TON = `'TON'` here, but `'0:000...000'` in `result_external_balances_history`. Normalize when merging:
```sql
CASE WHEN asset = 'TON'
    THEN '0:0000000000000000000000000000000000000000000000000000000000000000'
    ELSE asset
END AS asset
```

## ton.jetton_events

Jetton (token) transfer events.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | Partition key |
| source | string | Sender |
| destination | string | Receiver |
| jetton_master | string | Token contract address |
| amount | bigint | Raw units (check decimals per token) |
| tx_aborted | boolean | Filter with `tx_aborted = FALSE` |

**USDT on TON:** jetton_master = `0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE`, 6 decimals (divide by 1e6).

## ton.prices_daily

Daily token prices. **Decimals already incorporated** — no manual conversion.

| Column | Type | Notes |
|--------|------|-------|
| timestamp | timestamp | Start of day UTC |
| token_address | varchar | Raw format |
| price_usd | double | USD price **per raw unit** (e.g. per nanoTON for TON) |
| price_ton | double | TON price per raw unit |
| asset_type | varchar | `'Jetton'`, `'DEX LP'`, `'SLP'` |

**CRITICAL: price_usd is per RAW unit.** For TON: `price_usd ≈ 1.3e-9` (= ~$1.30 per 1e9 nanoTON). To get USD value: `raw_amount * price_usd`. Do NOT divide raw_amount by 1e9 first — that double-divides and gives 1e9x too small results.

Example: `sale_price * price_usd` = correct USD. `sale_price / 1e9 * price_usd` = WRONG (1e9x too small).

**End-of-month price:**
```sql
SELECT DATE_TRUNC('month', timestamp) AS month, token_address,
       MAX_BY(price_usd, timestamp) AS price_usd
FROM ton.prices_daily GROUP BY 1, 2
```

## ton.dex_trades

DEX swap data.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | Partition key |
| trader_address | string | |
| volume_usd | double | Trade volume in USD |
| project | string | `'ston.fi'`, `'dedust'`, etc. |

## ton.latest_balances

Current balance snapshot. Simpler than reconstructing from `balances_history`.

| Column | Type | Notes |
|--------|------|-------|
| address | string | |
| asset | string | Unique key: address + asset |
| amount | decimal(38,0) | Current balance (raw units) |

## dune.ton_foundation.dataset_labels

Named entities on TON (~3,150 labels). Source: [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels).

| Column | Type | Notes |
|--------|------|-------|
| address | string | Raw format |
| label | string | e.g. `'Binance'`, `'frozen_early_miner'` |
| organization | string | Parent org |
| category | string | **Never NULL** — `'CEX'`, `'dex'`, `'bridge'`, etc. |
| subcategory | string | Finer classification |

Category breakdown and key labels: see reference/labels.md.

## dune.ton_foundation.result_custodial_wallets

Custodial deposit wallets (~10.8M addresses). Details: see reference/labels.md.

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

## ton.nft_events

NFT transfer, sale, mint, bid events.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | Partition key |
| block_time | timestamp | |
| type | varchar | `'mint'`, `'sale'`, `'bid'`, `'transfer'`, `'put_on_sale'`, `'cancel_sale'` |
| nft_item_address | varchar | Individual NFT address |
| nft_item_index | varchar | Deterministic index |
| collection_address | varchar | Parent collection |
| owner_address | varchar | New owner after event |
| prev_owner | varchar | Previous owner |
| sale_price | decimal(38,0) | In nanoTON (divide by 1e9 for display, but use `* price_usd` for USD) |
| sale_type | varchar | `'auction'` or `'sale'` (fixed price) |
| marketplace_address | varchar | Which marketplace handled the sale |
| marketplace_fee | decimal(38,0) | Fee in nanoTON |
| payment_asset | varchar | Usually `'TON'` |
| content_onchain | varchar | JSON with auction params (bid, beneficiar, etc.) |
| tx_hash | varchar | |
| trace_id | varchar | |

**Volume calculation:** `WHERE type = 'sale'` captures both primary (Fragment auctions) and secondary sales. Use `sale_price * price_usd` for USD conversion (price_usd is per raw unit).

## ton.nft_metadata

NFT and collection metadata.

| Column | Type | Notes |
|--------|------|-------|
| type | varchar | `'item'` or `'collection'` |
| address | varchar | NFT item or collection address |
| parent_address | varchar | Collection address (for items) |
| name | varchar | Human-readable name |
| description | varchar | |
| image | varchar | URL |
| attributes | varchar | JSON traits |

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
