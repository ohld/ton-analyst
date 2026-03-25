-- Multi-hop ratio attribution for tracing fund flows
-- Example: TON Believers Fund withdrawal destination classification
-- 4 hops with CEX detection shortcut via result_cex_flows_daily
--
-- Pattern: for each hop, classify destinations. For intermediaries,
-- calculate source_share = source_inflow / total_inflow and attribute
-- each outflow proportionally. Propagate through 4 hops.
--
-- Categories: CEX, Staking, Liquid Staking, DEX Sell, Bridge, Unknown
--
-- Performance: ~250s for 4 hops on TBF data (77 recipients, 25M TON)

WITH source_contract AS (
    SELECT '0:ED1691307050047117B998B561D8DE82D31FBF84910CED6EB5FC92E7485EF8A7' AS addr  -- TBF
),

-- CEX detection: addresses that have deposited to CEX (via mat view)
-- Safe for detection, NOT for aggregation (see ../query-patterns.md gotcha #2 in cex-flows)
cex_senders AS (
    SELECT address FROM dune.ton_foundation.result_cex_flows_daily
    WHERE flow = 'to_cex'
      AND token_address = '0:0000000000000000000000000000000000000000000000000000000000000000'
      AND day >= DATE '2025-11-01'
    GROUP BY 1
),

bridges AS (SELECT DISTINCT address FROM dune.ton_foundation.dataset_labels WHERE category = 'bridge'),

dex_sellers AS (
    SELECT trader_address AS address FROM ton.dex_trades
    WHERE token_sold_address IN (
        '0:0000000000000000000000000000000000000000000000000000000000000000',  -- TON
        '0:671963027F7F85659AB55B821671688601CDCF1EE674FC7FBBB1A776A18D34A3'   -- pTON
    )
    AND block_date >= DATE '2025-11-01'
    GROUP BY 1 HAVING SUM(volume_ton) > 100
),

-- Step 1: get all outflows from source contract to recipient wallets
source_out AS (
    SELECT m.destination AS addr, SUM(CAST(m.value AS DOUBLE)) / 1e9 AS ton_from_source
    FROM ton.messages m CROSS JOIN source_contract sc
    WHERE m.source = sc.addr AND m.direction = 'in' AND NOT m.bounced
      AND m.block_date >= DATE '2025-11-11' AND m.value > 1000000000 AND m.destination IS NOT NULL
    GROUP BY 1
),

-- Step 2: HOP 1 — classify recipient outflows
hop1_in AS (
    SELECT h.addr, SUM(CAST(m.value AS DOUBLE)) / 1e9 AS total_in
    FROM source_out h INNER JOIN ton.messages m ON m.destination = h.addr
    WHERE m.direction = 'in' AND NOT m.bounced AND m.block_date >= DATE '2025-11-11' AND m.value > 100000000
    GROUP BY 1
),
hop1_out AS (
    SELECT h.addr AS from_addr, h.ton_from_source, m.destination AS to_addr,
        SUM(CAST(m.value AS DOUBLE)) / 1e9 AS ton_sent
    FROM source_out h INNER JOIN ton.messages m ON m.source = h.addr
    WHERE m.direction = 'in' AND NOT m.bounced AND m.block_date >= DATE '2025-11-11'
      AND m.value > 100000000 AND m.destination IS NOT NULL AND m.destination != h.addr
    GROUP BY 1, 2, 3
),
hop1_classified AS (
    SELECT o.to_addr,
        -- Ratio attribution: source_share * outflow
        o.ton_sent * (o.ton_from_source / GREATEST(COALESCE(hi.total_in, o.ton_from_source), 0.001)) AS attributed,
        CASE
            WHEN o.to_addr LIKE '-1:%' THEN 'Staking'
            WHEN cs.address IS NOT NULL THEN 'CEX'
            WHEN br.address IS NOT NULL THEN 'Bridge'
            WHEN ds.address IS NOT NULL THEN 'DEX Sell'
            ELSE 'intermediate'
        END AS category
    FROM hop1_out o
    LEFT JOIN hop1_in hi ON hi.addr = o.from_addr
    LEFT JOIN cex_senders cs ON cs.address = o.to_addr
    LEFT JOIN bridges br ON br.address = o.to_addr
    LEFT JOIN dex_sellers ds ON ds.address = o.to_addr
)

-- Repeat hop2, hop3, hop4 with same pattern:
-- 1. Collect intermediates from previous hop
-- 2. Get their total inflows and outflows
-- 3. Calculate ratio, classify destinations
-- 4. Unresolved → next hop

-- Final: UNION ALL classified from all hops + unresolved + held (balance)

SELECT category, SUM(attributed) AS ton_amount
FROM hop1_classified WHERE category != 'intermediate'
GROUP BY 1
ORDER BY 2 DESC
