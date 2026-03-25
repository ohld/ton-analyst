-- NFT and Collection Name Resolution
--
-- Question: How do I resolve NFT names and collection names?
-- Uses: ton.nft_metadata self-join (item → parent collection)
-- Gotcha: .ton domain names stored in content_onchain JSON, not name field

WITH NFT_NAMES AS (
    SELECT address,
           MAX(parent_address) AS parent_address,
           MAX_BY(
               COALESCE(name, json_extract_scalar(content_onchain, '$.domain') || '.ton'),
               adding_date
           ) AS name
    FROM ton.nft_metadata GROUP BY 1
)
, NFT_COLLECTION_NAME AS (
    SELECT NFT_NAMES.address,
           COALESCE(COLLECTION.name, NFT_NAMES.name) AS name
    FROM NFT_NAMES
    LEFT JOIN NFT_NAMES AS COLLECTION ON COLLECTION.address = NFT_NAMES.parent_address
    WHERE COALESCE(COLLECTION.name, NFT_NAMES.name) IS NOT NULL
)
SELECT * FROM NFT_COLLECTION_NAME LIMIT 50
