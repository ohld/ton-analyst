# ton.nft_events

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
| sale_type | varchar | `'auction'` or `'sale'` (fixed price). Describes the MECHANISM, not completion status. Both values appear with `type='sale'` (= completed). Never filter `sale_type='sale'` to get "all sales" — that excludes auctions (~87% of username sales). |
| marketplace_address | varchar | Which marketplace handled the sale |
| marketplace_fee | decimal(38,0) | Fee in nanoTON |
| payment_asset | varchar | Usually `'TON'` |
| content_onchain | varchar | JSON with auction params (bid, beneficiar, etc.) |
| tx_hash | varchar | |
| trace_id | varchar | |

**Volume calculation:** `WHERE type = 'sale' AND payment_asset = 'TON'` for TON-denominated sales. Use `sale_price * price_usd` for USD conversion (price_usd is per raw unit).

**CRITICAL: always filter `payment_asset = 'TON'`** when using TON price for conversion. Some NFTs are sold for jettons (DOGS, USDT, etc.) — their `sale_price` is in that jetton's raw units, NOT nanoTON. Multiplying by TON's price gives wildly wrong results (e.g. $2K of real volume inflated to $114M).

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

## Related Tables

### dune.telegram.stickers / dune.telegram.stickers_sales

Off-chain data uploaded by Telegram team.
- `stickers` — primary sales data (release_time, price, sold count)
- `stickers_sales` — marketplace sales (platform, block_time, amount_ton, amount_usd)

### Decoded project tables

Project-specific decoded tables exist in the Dune spellbook for EVAA, Affluent, StormTrade, and others. See [Dune Spellbook — TON](https://github.com/duneanalytics/spellbook/tree/main/dbt_subprojects/daily_spellbook/models/ton).
