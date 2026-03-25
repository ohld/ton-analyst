# CEX Flow Analysis Patterns

Patterns for analyzing centralized exchange (CEX) fund flows on TON: deposits, withdrawals, custodial wallet identification, net flow calculation, and CEX-to-CEX exclusion.

## Critical Gotchas

1. **CEX internal transfers are ~42% of volume.** When counting real CEX deposits, exclude transfers where `source` is also in `result_custodial_wallets` — otherwise you count CEX↔CEX shuffling as user deposits.
2. **`result_cex_flows_daily` — detection OK, aggregation WRONG.** Safe for checking if an address deposited to CEX (`WHERE flow = 'to_cex' GROUP BY address`). UNSAFE for total market flows — inflates 2-3x due to CEX-to-CEX and internal transfers. For total net CEX flows, use `ton.messages` with dual CEX join (see CEX_NET_FLOW pattern below).
3. **CEX-to-CEX exclusion requires dual JOIN.** When computing net CEX inflows/outflows, JOIN both source and destination against ALL_CEX. Exclude rows where BOTH match. Without this, CEX rebalancing inflates numbers by 40-100%.

## CEX_NET_FLOW (Correct CEX Aggregation)

For total market net CEX flows, use `ton.messages` with dual JOIN — NOT `result_cex_flows_daily`.

```sql
, ALL_CEX AS (
    SELECT address, label FROM dune.ton_foundation.dataset_labels WHERE category = 'CEX'
    UNION ALL
    SELECT address, label FROM dune.ton_foundation.result_custodial_wallets WHERE category = 'CEX'
)

-- Inflow: non-CEX → CEX; Outflow: CEX → non-CEX; CEX-to-CEX excluded
SELECT
    DATE_TRUNC('month', m.block_date) AS month,
    SUM(CASE WHEN dst.address IS NOT NULL AND src.address IS NULL
        THEN CAST(m.value AS DOUBLE) / 1e9 END) AS inflow,
    SUM(CASE WHEN src.address IS NOT NULL AND dst.address IS NULL
        THEN CAST(m.value AS DOUBLE) / 1e9 END) AS outflow
FROM ton.messages m
LEFT JOIN ALL_CEX dst ON m.destination = dst.address
LEFT JOIN ALL_CEX src ON m.source = src.address
WHERE m.direction = 'in' AND NOT m.bounced AND m.value > 0
  AND (dst.address IS NOT NULL OR src.address IS NOT NULL)
  AND NOT (dst.address IS NOT NULL AND src.address IS NOT NULL)  -- ← CEX-to-CEX excluded
GROUP BY 1
```

**Why not `result_cex_flows_daily` for aggregation?** It includes internal CEX transfers (hot wallet ↔ custodial), inflating totals 2-3x. Safe for per-address detection ("did address X deposit to CEX?"), unsafe for market-level totals.

## CEX Detection Shortcut

Use `result_cex_flows_daily` to check if an intermediate address has ever deposited to CEX — useful in flow tracing (see flow-tracing.md):

```sql
, cex_senders AS (
    SELECT address FROM dune.ton_foundation.result_cex_flows_daily
    WHERE flow = 'to_cex' AND token_address = '0:000...000' AND day >= DATE '2025-01-01'
    GROUP BY 1
)
```

## Related

- CEX attribution capping: gotcha #19 in patterns.md
- `result_custodial_wallets` schema: tables.md
- Multi-hop tracing with CEX as destination: flow-tracing.md
