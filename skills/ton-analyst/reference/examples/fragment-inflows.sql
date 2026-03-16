-- Fragment Inflows by Payment Type (monthly)
-- Classifies ALL TON payments to Fragment by comment patterns and opcodes.
-- Excludes Fragment→Fragment rebalancing (operational noise).
-- Reference: https://dune.com/queries/6836467
--
-- Categories:
--   Stars Purchase, TG Ads, TG Premium, TG Gift Market, TG Gateway,
--   TG Premium Giveaway, Bot Username Fee, Bot Custom Domain Fee,
--   Username Auction Bids (includes ALL bids, losers refunded — volume ≠ revenue),
--   Gift NFT Mint (gas only), Topups from Telegram Treasury, Other

SELECT
    date_trunc('month', m.block_date) AS month,
    CASE
        WHEN m.comment LIKE '%Telegram Stars%Ref#%' THEN 'Stars Purchase'
        WHEN m.comment LIKE '%Telegram Ad account top up%Ref#%' THEN 'TG Ads'
        WHEN m.comment LIKE '%Telegram Premium%Ref#%' THEN 'TG Premium'
        WHEN m.comment LIKE '%Telegram account top up%Ref#%' THEN 'TG Gift Market'
        WHEN m.comment LIKE '%Telegram Gateway%Ref#%' THEN 'TG Gateway'
        WHEN m.comment LIKE '%Prepaid Subscription%Ref#%' THEN 'TG Premium Giveaway'
        WHEN m.comment LIKE '%Bot Username Upgrade Fee%' THEN 'Bot Username Fee'
        WHEN m.comment LIKE '%Fee to upgrade%for bots%Ref#%' THEN 'Bot Custom Domain Fee'
        WHEN m.opcode = 1178019994 THEN 'Username Auction Bids'
        WHEN m.opcode = 923790417 THEN 'Gift NFT Mint (gas)'
        WHEN m.source = UPPER('0:8c397c43f9ff0b49659b5d0a302b1a93af7ccc63e5f5c0c4f25a9dc1f8b47ab3')
            THEN 'Topups from Telegram Treasury'
        ELSE 'Other'
    END AS payment_type,
    COUNT(*) AS tx_count,
    COUNT(DISTINCT m.source) AS unique_payers,
    SUM(m.value) / 1e9 AS total_ton,
    GET_HREF(
        'https://tonviewer.com/transaction/'
        || LOWER(TO_HEX(FROM_BASE64(MAX_BY(m.trace_id, m.value)))),
        CAST(CAST(MAX(m.value) / 1e9 AS DECIMAL(18,1)) AS VARCHAR) || ' TON'
    ) AS largest_tx
FROM ton.messages m
INNER JOIN dune.ton_foundation.dataset_labels lbl
    ON lbl.address = m.destination AND lbl.label = 'fragment'
LEFT JOIN dune.ton_foundation.dataset_labels src_lbl
    ON src_lbl.address = m.source AND src_lbl.label = 'fragment'
WHERE m.direction = 'in'
AND NOT m.bounced
AND m.value > 0
AND m.block_date >= DATE '2025-01-01'
AND src_lbl.address IS NULL  -- exclude Fragment→Fragment rebalancing
GROUP BY 1, 2
ORDER BY 1 DESC, 5 DESC
