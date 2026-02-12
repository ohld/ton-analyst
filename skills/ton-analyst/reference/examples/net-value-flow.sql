-- Net Value Flow Between Addresses
--
-- Question: What is the net USD value flowing between two sets of addresses?
-- Uses: UNNEST trick to create bidirectional edges — GROUP BY automatically nets flows
-- Gotcha: Adjust date range and minimum transfer size for your use case

WITH JETTON_TRANSFERS AS (
    SELECT block_date, source, destination, jetton_master AS token_address, amount
    FROM ton.jetton_events
    WHERE tx_aborted = FALSE
      AND block_date >= DATE '2026-01-01'
      AND amount > 0
      AND source IS NOT NULL AND destination IS NOT NULL
)

, TON_TRANSFERS AS (
    SELECT block_date, source, destination,
           '0:0000000000000000000000000000000000000000000000000000000000000000' AS token_address,
           value AS amount
    FROM ton.messages
    WHERE direction = 'in' AND NOT bounced
      AND value > POWER(10, 9 + 1)  -- at least 10 TON
      AND block_date >= DATE '2026-01-01'
)

, TRANSFERS AS (
    SELECT * FROM JETTON_TRANSFERS UNION ALL SELECT * FROM TON_TRANSFERS
)

-- UNNEST trick: two rows per transfer (positive + negative) → GROUP BY nets flows
SELECT from_, to_,
       SUM(amount_ * P.price_usd) AS net_volume_usd
FROM TRANSFERS T
CROSS JOIN UNNEST (ARRAY[
    ROW(source, destination, amount),
    ROW(destination, source, amount * -1)
]) AS T(from_, to_, amount_)
INNER JOIN ton.prices_daily P
    ON P.timestamp = T.block_date AND P.token_address = T.token_address
GROUP BY 1, 2
