# NFT and Fragment SQL Fragments

## NFT Volume Calculation

```sql
-- Total NFT sales volume (includes Fragment primary + all secondary)
, NFT_SALES AS (
    SELECT
        DATE_TRUNC('month', block_date) AS block_date,
        collection_address,
        SUM(sale_price) / 1e9 AS volume_ton,
        SUM(sale_price * P.price_usd) AS volume_usd, -- price_usd is per raw unit
        COUNT(*) AS sales,
        COUNT(DISTINCT owner_address) AS unique_buyers
    FROM ton.nft_events E
    LEFT JOIN (
        SELECT timestamp AS block_date, price_usd
        FROM ton.prices_daily
        WHERE token_address LIKE '0:000000000%'
    ) P ON P.block_date = E.block_date
    WHERE E.type = 'sale'
      AND E.block_date >= DATE '...'
    GROUP BY 1, 2
)
```

## NFT Asset Classification CTE

```sql
, NFT_CLASSIFIED AS (
    SELECT *,
        CASE
            WHEN collection_address = '0:80D78A35F955A14B679FAA887FF4CD5BFC0F43B4A4EEA2A7E6927F3701B273C2' THEN 'Usernames'
            WHEN collection_address = '0:0E41DC1DC3C9067ED24248580E12B3359818D83DEE0304FABCF80845EAFAFDB2' THEN 'Numbers'
            WHEN collection_address IN (
                '0:B774D95EB20543F186C06B371AB88AD704F7E256130CAF96189368A7D0CB6CCF',
                '0:E1955ABA7249F23E4FD2086654A176516D98B134E0DF701302677C037C358B17'
            ) THEN 'DNS'
            WHEN collection_address IN (SELECT col_address FROM dune.rdmcd.result_gifts_collection_addresses) THEN 'Gifts'
            ELSE 'Other NFTs'
        END AS asset_class
    FROM ton.nft_events
    WHERE type = 'sale'
)
```
