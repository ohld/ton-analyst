-- Real Wallets with 1K+ / 10K+ TON Over Time
--
-- Question: How many real human wallets hold significant TON balances over time?
-- Uses: ALL_LABELS + REAL_WALLETS pattern (see reference/patterns.md), threshold crossings + running sum
-- Note: Sparse output — only days with crossings. Dune line chart handles gaps automatically.

WITH _ AS (SELECT 1)

-- ALL_LABELS: combine all labeled (non-user) addresses
, ALL_LABELS AS (
    SELECT address FROM dune.ton_foundation.dataset_labels
    UNION ALL
    SELECT address FROM dune.ton_foundation.result_custodial_wallets
    UNION ALL
    SELECT address FROM dune.ton_foundation.result_sybil_wallets
)

-- REAL_WALLETS: wallet interface + not in any label table
, REAL_WALLETS AS (
    SELECT A.address
    FROM ton.accounts A
    LEFT JOIN ALL_LABELS AL ON A.address = AL.address
    WHERE cardinality(FILTER(A.interfaces, i -> regexp_like(i, '^wallet_'))) > 0
      AND AL.address IS NULL
)

, DAILY_BALANCES AS (
    SELECT B.block_date, B.address,
           MAX_BY(B.amount, B.block_time) / 1e9 AS ton_balance
    FROM ton.balances_history B
    INNER JOIN REAL_WALLETS RW ON B.address = RW.address
    WHERE B.asset = 'TON'
    GROUP BY 1, 2
)

, WITH_PREV AS (
    SELECT block_date, address, ton_balance,
           LAG(ton_balance, 1, 0) OVER (PARTITION BY address ORDER BY block_date) AS prev_balance
    FROM DAILY_BALANCES
)

, CROSSINGS AS (
    SELECT block_date,
        SUM(CASE WHEN ton_balance >= 1000 AND prev_balance < 1000 THEN 1
                 WHEN ton_balance < 1000 AND prev_balance >= 1000 THEN -1 ELSE 0 END) AS delta_1k,
        SUM(CASE WHEN ton_balance >= 10000 AND prev_balance < 10000 THEN 1
                 WHEN ton_balance < 10000 AND prev_balance >= 10000 THEN -1 ELSE 0 END) AS delta_10k
    FROM WITH_PREV GROUP BY 1
)

SELECT block_date,
       SUM(delta_1k) OVER (ORDER BY block_date) AS wallets_1k_plus,
       SUM(delta_10k) OVER (ORDER BY block_date) AS wallets_10k_plus
FROM CROSSINGS ORDER BY block_date
