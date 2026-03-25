# ton.dex_trades

DEX swap data. Each row = one swap.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | Partition key |
| block_time | timestamp | |
| trader_address | string | Wallet that initiated the swap |
| token_sold_address | string | Token being sold (raw address) |
| token_bought_address | string | Token being bought (raw address) |
| amount_sold_raw | bigint | Raw amount sold (check token decimals) |
| amount_bought_raw | bigint | Raw amount bought |
| volume_ton | double | Trade volume in TON |
| volume_usd | double | Trade volume in USD |
| pool_address | string | DEX pool contract address |
| router_address | string | DEX router contract |
| project | string | `'ston.fi'`, `'dedust'`, etc. |
| project_type | string | `'dex'` |
| trace_id | string | For tonviewer links |
| tx_hash | string | |
| referral_address | string | Referral (if any) |
| version | int | |

**TON/pTON token addresses** (covers 89% of all TON DEX sell volume in 2026):
```sql
-- "Selling TON" = token_sold_address is one of these
token_sold_address IN (
    '0:0000000000000000000000000000000000000000000000000000000000000000',  -- native TON (DeDust, swap.coffee)
    '0:671963027F7F85659AB55B821671688601CDCF1EE674FC7FBBB1A776A18D34A3',  -- pTON v2 (STON.fi, largest ~57%)
    '0:8CDC1D7640AD5EE326527FC1AD0514F468B30DC84B0173F0E155F451B4E11F7C',  -- pTON v1 (STON.fi, ~13%)
    '0:949C4C66760C002800E2FA3D8A3CA4E1C90A9373B53AE7472033483BF14CD95E',  -- pTON (TONCO)
    '0:D0A1CE4CDC187C79615EA618BD6C29617AF7A56D966F5A192A768F345EE63FD2'   -- wTON (negligible)
)
```

**USDT address:** `0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE` (6 decimals)

**Top USDT/TON pools by TVL (Mar 2026):**
| Pool | Project | TVL USD |
|------|---------|---------|
| STON.fi v2 pool | STON.fi (pTON v2) | $5.7M |
| STON.fi v1 pool | STON.fi (pTON v1) | $4.9M |
| DeDust pool | DeDust (native TON) | $0.7M |
| TONCO pool | TONCO | $0.1M |

Pool addresses: query `dune.ton_foundation.result_dex_pools_latest` for current pool addresses.

**tsTON** is a liquid staking derivative. Selling tsTON = indirect TON sell pressure, but requires multi-hop tracking. Not included in direct TON sell analysis.

**NO `token_sold_symbol` column exists.** Use token addresses directly. Use `dune.ton_foundation.result_dex_pools_latest` for pool discovery.

**swap.coffee** uses native TON (`0:0000000000000000000000000000000000000000000000000000000000000000`) directly, no separate pTON.

## Related Materialized Views

### dune.ton_foundation.result_dex_pools_daily

DEX pool metrics by day. Use for TVL tracking, volume analysis, pool discovery.

Source query: TBD

### dune.ton_foundation.result_dex_pools_latest

Current DEX pool state. Use for pool discovery and current TVL lookups.

Source query: TBD
