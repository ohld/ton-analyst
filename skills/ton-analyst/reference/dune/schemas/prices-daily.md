# ton.prices_daily

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

## Related Materialized Views

### dune.ton_foundation.result_jetton_price_daily

Jetton prices computed by TON Foundation. May cover tokens not in `ton.prices_daily`.

Source query: TBD
