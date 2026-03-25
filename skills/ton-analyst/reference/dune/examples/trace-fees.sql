-- Trace Fee Calculation
--
-- Question: How much gas did each trace initiator pay?
-- Uses: ton.transactions (total_fees) + ton.messages (fwd_fee), joined by trace_id
-- Gotcha: trace_id = hash of the first transaction in the trace

WITH _ AS (SELECT 1)

, _TRACE_FEES AS (
    SELECT block_date, trace_id, T.total_fees AS fees
    FROM ton.transactions T
    WHERE T.block_date >= NOW() - INTERVAL '30' DAY
    UNION ALL
    SELECT block_date, trace_id, M.fwd_fee AS fees
    FROM ton.messages M
    WHERE M.block_date >= NOW() - INTERVAL '30' DAY AND M.direction = 'in'
)

, TRACE_FEES AS (
    SELECT trace_id, SUM(fees * P.price_usd) AS fee_usd
    FROM _TRACE_FEES TR
    LEFT JOIN ton.prices_daily P
        ON P.timestamp = TR.block_date
        AND P.token_address = '0:0000000000000000000000000000000000000000000000000000000000000000'
    GROUP BY 1
)

, TRACE_INITIATOR AS (
    SELECT T.trace_id, T.account
    FROM ton.transactions T
    WHERE T.block_date >= NOW() - INTERVAL '30' DAY AND T.trace_id = T.hash
)

SELECT TI.account, SUM(TF.fee_usd) AS total_fee_usd
FROM TRACE_INITIATOR TI
JOIN TRACE_FEES TF ON TI.trace_id = TF.trace_id
GROUP BY 1 ORDER BY 2 DESC LIMIT 50
