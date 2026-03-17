-- Fragment Outflows by Payout Type (monthly)
-- Classifies ALL TON outflows from Fragment by comment patterns and opcodes.
-- Excludes Fragment→Fragment rebalancing.
-- Reference: https://dune.com/queries/6845207
--
-- Opcodes verified via TONAPI (destination contract interfaces):
--   697974293: dest=nft_item+teleitem → auction settlement (sends bid TON to NFT contracts)
--   1178019995: dest=nft_collection → auction collection trigger (0.06 TON gas)
--   1607220500: dest=nft_item+teleitem → NFT item notification (0.1 TON gas)

SELECT
    date_trunc('month', m.block_date) AS month,
    CASE
        WHEN m.comment LIKE '%Reward from Telegram bot%Ref#%' THEN 'Bot Rewards'
        WHEN m.comment LIKE '%Reward from Telegram channel%Ref#%' THEN 'Channel Rewards'
        WHEN m.comment LIKE '%Reward from Telegram user%Ref#%' THEN 'User Stars Rewards'
        WHEN m.comment LIKE '%Auction proceeds%' THEN 'Auction Proceeds (to seller)'
        WHEN m.comment LIKE '%Telegram Stars%Ref#%' THEN 'Stars Refund'
        WHEN m.comment LIKE '%Telegram Premium%' THEN 'Premium Refund'
        WHEN m.comment LIKE '%Telegram Ad account%' THEN 'Ad Account Refund'
        WHEN m.comment LIKE '%Telegram account top up%' THEN 'Gift Market Refund'
        WHEN m.opcode = 697974293 THEN 'Username Auction Settlement (to NFT contract)'
        WHEN m.opcode = 1178019995 THEN 'Auction Collection Trigger (gas)'
        WHEN m.opcode = 1607220500 THEN 'NFT Item Notification (gas)'
        WHEN m.destination = UPPER('0:8c397c43f9ff0b49659b5d0a302b1a93af7ccc63e5f5c0c4f25a9dc1f8b47ab3')
            THEN 'Fragment → Telegram Treasury'
        WHEN m.comment = '' AND m.opcode = 0 THEN 'Empty transfer (opcode 0)'
        ELSE 'Other'
    END AS payout_type,
    COUNT(*) AS tx_count,
    COUNT(DISTINCT m.destination) AS unique_recipients,
    SUM(m.value) / 1e9 AS total_ton,
    GET_HREF(
        'https://tonviewer.com/transaction/'
        || LOWER(TO_HEX(FROM_BASE64(MAX_BY(m.trace_id, m.value)))),
        CAST(CAST(MAX(m.value) / 1e9 AS DECIMAL(18,1)) AS VARCHAR) || ' TON'
    ) AS largest_tx
FROM ton.messages m
INNER JOIN dune.ton_foundation.dataset_labels lbl
    ON lbl.address = m.source AND lbl.label = 'fragment'
LEFT JOIN dune.ton_foundation.dataset_labels dst_lbl
    ON dst_lbl.address = m.destination AND dst_lbl.label = 'fragment'
WHERE m.direction = 'in'
AND NOT m.bounced
AND m.value > 0
AND m.block_date >= DATE '2025-01-01'
AND dst_lbl.address IS NULL  -- exclude Fragment→Fragment rebalancing
GROUP BY 1, 2
ORDER BY 1 DESC, 5 DESC
