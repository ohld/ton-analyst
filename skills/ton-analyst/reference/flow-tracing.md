# Flow Tracing Patterns

Patterns for tracing fund flows through multiple wallets on TON: multi-hop ratio attribution, forward-fill for change-log tables, and balance reconstruction.

## Critical Gotchas

1. **Multi-hop ratio attribution for flow tracing.** When tracing funds through intermediary wallets: `bf_share = source_inflow / total_inflow`. Apply ratio to each outflow. Propagate through hops. This prevents double-counting when intermediaries have non-source income. See examples/multi-hop-attribution.sql.
2. **`balances_history` records changes only.** No row = no change that day. For daily charts, generate a day sequence and forward-fill: seed with known initial value, then `MAX(CASE WHEN balance IS NOT NULL THEN dt END) OVER (ORDER BY dt)` to carry forward.

## Multi-Hop Flow Tracing (Ratio Attribution)

Trace fund flows through multiple wallet hops with ratio-based attribution.

**Approach:**
1. Start from source contract, get direct outflows (hop 1)
2. At each hop, classify destination: CEX, staking (-1:), liquid staking, DEX, bridge, or intermediate
3. For intermediaries, calculate `source_share = source_inflow / total_inflow`
4. Attribute each outflow proportionally: `attributed = outflow * source_share`
5. Repeat for 3-4 hops

**CEX detection shortcut:** Use `result_cex_flows_daily` to check if an intermediate address has ever deposited to CEX — avoids extra hops through custodial wallets (see cex-flows.md for the CTE).

**Destination categories (priority order):**
1. `-1:` prefix → Masterchain staking
2. Known liquid staking protocols → Liquid Staking
3. In `cex_senders` → CEX
4. In `dataset_labels` WHERE category = 'bridge' → Bridge
5. In `dex_trades` as seller → DEX Sell
6. Otherwise → Intermediate (trace next hop)

**Performance:** 4-hop ratio attribution runs in ~250s on Dune. Each additional hop adds ~60s. 4 hops covers 93%+ of flows for TBF-style analysis.

See `examples/multi-hop-attribution.sql` for full 4-hop implementation.

## FORWARD_FILL (MAX_BY)

Both `ton.balances_history` and `result_external_balances_history` are change-logs. To get balance on date X, find the latest row where `block_date <= X`:

```sql
-- Monthly snapshot: balance from the last change within each month
, BALANCE_UPDATES AS (
    SELECT DATE_TRUNC('month', block_date) AS month, address, asset,
           MAX_BY(amount, block_date) AS amount
    FROM ton.balances_history
    GROUP BY 1, 2, 3
)
```

For daily forward-fill (line charts), seed with a known initial value to skip unnecessary partition scans:

```sql
, seed AS (SELECT DATE '2025-11-11' AS dt, 1317374904.39 AS balance_ton),  -- known balance

, balance_changes AS (
    SELECT CAST(block_date AS DATE) AS dt, CAST(amount AS DOUBLE) / 1e9 AS balance_ton,
        ROW_NUMBER() OVER (PARTITION BY CAST(block_date AS DATE) ORDER BY block_time DESC) AS rn
    FROM ton.balances_history WHERE address = '0:...' AND asset = 'TON' AND block_date >= DATE '2025-11-11'
),

, daily_balance AS (
    SELECT dt, balance_ton FROM seed
    UNION ALL SELECT dt, balance_ton FROM balance_changes WHERE rn = 1
),

, all_days AS (SELECT dt FROM UNNEST(SEQUENCE(DATE '2025-11-11', CURRENT_DATE, INTERVAL '1' DAY)) AS t(dt)),

, joined AS (
    SELECT d.dt, b.balance_ton,
        MAX(CASE WHEN b.balance_ton IS NOT NULL THEN d.dt END) OVER (ORDER BY d.dt) AS last_known_dt
    FROM all_days d LEFT JOIN daily_balance b ON b.dt = d.dt
)

SELECT j.dt, COALESCE(j.balance_ton, lb.balance_ton) AS balance_ton
FROM joined j LEFT JOIN daily_balance lb ON lb.dt = j.last_known_dt
```

## Related

- CEX flow patterns and net flow calculation: cex-flows.md
- Change-log table schemas: tables.md
- Balance tier classification: patterns.md (BALANCE_TIERS)
