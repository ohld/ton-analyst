# Labels and Real Users CTEs

## Counterparty Filters

When classifying wallets by who they send to, remove self-messages before joining
destinations to labels. Keep the filter narrow and still require at least one
non-self outgoing transfer to a labelled organization.

```sql
, TRANSFERS_FOR_CLASSIFICATION AS (
    SELECT *
    FROM TRANSFERS
    WHERE source IS NULL OR destination IS NULL OR source <> destination
)
```

For custodial-wallet detectors, apply this before `SOURCE_STATS` /
`DESTINATION_STATS`. A wallet that only sends to itself after this filter should
not be classified as custodial.

## ALL_LABELS + REAL_USERS

Foundation CTEs reused across most queries.

```sql
-- Combine all labeled (non-user) addresses from 3 sources
, ALL_LABELS AS (
    SELECT address, label
    FROM dune.ton_foundation.dataset_labels
    UNION ALL
    SELECT address, label
    FROM dune.ton_foundation.result_custodial_wallets
    UNION ALL
    SELECT address, 'sybil' AS label
    FROM dune.ton_foundation.result_sybil_wallets
)

-- Real users: wallet interface + not in any label table (~39.7M addresses)
, REAL_USERS AS (
    SELECT A.address
    FROM ton.accounts A
    LEFT JOIN ALL_LABELS AL ON A.address = AL.address
    WHERE cardinality(FILTER(
            A.interfaces,
            i -> regexp_like(i, '^wallet_.*') OR regexp_like(i, '^multisig.*')
        )) > 0
      AND AL.address IS NULL
)
```

## DEFI_LABELS (Gap Filler)

Many DeFi pool contracts are NOT in `dataset_labels`. Pull from pool tables, exclude already-labeled:

```sql
, DEFI_LABELS AS (
    SELECT DEFI.address, ANY_VALUE(label) AS label, ANY_VALUE(category) AS category
    FROM (
        SELECT DP.pool AS address, DP.project AS label, 'DEX' AS category
        FROM dune.ton_foundation.result_dex_pools_latest DP
        UNION ALL
        SELECT pool_address AS address, ANY_VALUE(project) AS label, 'defi' AS category
        FROM dune.ton_foundation.result_external_balances_history
        GROUP BY 1
    ) AS DEFI
    LEFT JOIN dune.ton_foundation.dataset_labels L ON L.address = DEFI.address
    WHERE L.address IS NULL
    GROUP BY 1
)

, LABELS AS (
        SELECT address, label, category
        FROM dune.ton_foundation.dataset_labels
    UNION ALL
        SELECT address, label, category
        FROM dune.ton_foundation.result_custodial_wallets
    UNION ALL
        SELECT * FROM DEFI_LABELS
)
```
