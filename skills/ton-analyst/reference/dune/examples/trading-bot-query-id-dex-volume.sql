-- created with github.com/ohld/ton-analyst
-- Attribute DEX trades to a trading bot when it uses a stable query_id namespace.
-- x1000 example based on the public xRocket Trading Bots on TON dashboard.

WITH jetton_query_ids AS (
    SELECT
        trace_id,
        block_date,
        MAX(query_id) AS query_id
    FROM ton.jetton_events
    WHERE block_date >= CURRENT_DATE - INTERVAL '6' MONTH
      AND block_date >= DATE '2025-09-25'
      AND query_id IS NOT NULL
    GROUP BY 1, 2
),

bot_trades AS (
    SELECT
        DATE_TRUNC('day', dt.block_time) AS date,
        dt.trader_address,
        dt.volume_ton,
        dt.volume_usd
    FROM ton.dex_trades dt
    LEFT JOIN jetton_query_ids je
      ON dt.trace_id = je.trace_id
     AND dt.block_date = je.block_date
    WHERE dt.block_date >= CURRENT_DATE - INTERVAL '6' MONTH
      AND dt.block_date >= DATE '2025-09-25'
      AND BITWISE_RIGHT_SHIFT(COALESCE(dt.query_id, je.query_id), 32) = 988547769
)

SELECT
    date,
    TRY_CAST(SUM(volume_ton) AS DECIMAL(38, 9)) AS volume_ton,
    TRY_CAST(SUM(volume_usd) AS DECIMAL(38, 2)) AS volume_usd,
    COUNT(*) AS daily_trades,
    COUNT(DISTINCT trader_address) AS daily_unique_traders
FROM bot_trades
GROUP BY 1
ORDER BY date DESC;
