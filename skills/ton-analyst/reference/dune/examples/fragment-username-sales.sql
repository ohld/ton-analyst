-- created with github.com/ohld/ton-analyst
-- Fragment Username NFT — Biggest Sales by Month
--
-- Question: What are the biggest Telegram username sales on Fragment?
-- Uses: ton.nft_events + ton.nft_metadata (for @username resolution) + ton.prices_daily
--
-- Key learnings:
--   1. nft_metadata.name already includes '@' prefix for usernames — do NOT prepend another '@'
--   2. type='sale' = completed sale (both fixed-price AND auction). type='bid' = auction bid.
--      NEVER add sale_type='sale' filter — it excludes ~87% of sales (all auctions).
--   3. sale_type distinguishes mechanism: 'sale' = fixed-price, 'auction' = auction-based.
--      Both are valid completed sales when type='sale'.
--   4. Auction sales have NULL trace_id — use COALESCE fallback to NFT item address link
--   5. Use ton_address_raw_to_user_friendly(addr, false) for user wallets — shows UQ (non-bounceable)
--   6. Embed transaction hyperlink inside datetime column for interactive dashboards
--
-- Collection addresses:
--   Usernames: 0:80D78A35F955A14B679FAA887FF4CD5BFC0F43B4A4EEA2A7E6927F3701B273C2
--   Numbers:   0:0E41DC1DC3C9067ED24248580E12B3359818D83DEE0304FABCF80845EAFAFDB2
--
-- Reference: https://dune.com/queries/6849668

WITH USERNAME_NAMES AS (
    SELECT
        address AS nft_item_address,
        MAX(name) AS username
    FROM ton.nft_metadata
    WHERE type = 'item'
      AND parent_address = '0:80D78A35F955A14B679FAA887FF4CD5BFC0F43B4A4EEA2A7E6927F3701B273C2'
    GROUP BY 1
)

SELECT
    N.username,
    E.sale_price / 1e9 AS price_ton,
    E.sale_price * P.price_usd AS price_usd,
    GET_HREF(
        COALESCE(
            'https://tonviewer.com/transaction/' || LOWER(TO_HEX(FROM_BASE64(E.trace_id))),
            'https://tonviewer.com/' || ton_address_raw_to_user_friendly(E.nft_item_address, true)
        ),
        DATE_FORMAT(E.block_time, '%Y-%m-%d %H:%i')
    ) AS sale_time,
    E.sale_type,
    GET_HREF(
        'https://tonviewer.com/' || ton_address_raw_to_user_friendly(E.owner_address, false),
        SUBSTR(ton_address_raw_to_user_friendly(E.owner_address, false), 1, 6) || '...' || SUBSTR(ton_address_raw_to_user_friendly(E.owner_address, false), -4)
    ) AS buyer
FROM ton.nft_events E
LEFT JOIN USERNAME_NAMES N
    ON N.nft_item_address = E.nft_item_address
LEFT JOIN ton.prices_daily P
    ON P.timestamp = CAST(E.block_date AS TIMESTAMP)
    AND P.token_address LIKE '0:000000000%'
WHERE E.type = 'sale'
  AND E.collection_address = '0:80D78A35F955A14B679FAA887FF4CD5BFC0F43B4A4EEA2A7E6927F3701B273C2'
  AND E.payment_asset = 'TON'
  AND E.block_date >= DATE '2026-02-01'
  AND E.block_date < DATE '2026-03-01'
ORDER BY E.sale_price DESC
LIMIT 50
