# Reusable SQL Patterns

CTEs, classification logic, and conventions for TON Dune queries.

## Critical Gotchas

1. **`dataset_labels.category` is never NULL.** No COALESCE needed. Source: [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels)
2. **`result_custodial_wallets` already has `category = 'CEX'`.** Just UNION ALL with dataset_labels.
3. **DeFi pool addresses are often NOT in dataset_labels.** Build DEFI_LABELS CTE from `result_dex_pools_latest` + `result_external_balances_history` — see below.
4. **Early miners are `uninit` NOT `frozen`.** Label=`frozen_early_miner`, status=`uninit`.
5. **Balance is in nanoTON.** Always divide by `1e9`.
6. **Never sum TON + USDT** — different prices. Show separate columns.
7. **Always add `LIMIT 50`** when exploring. TON has 145M+ accounts.
8. **Wallet detection via interfaces:** `cardinality(FILTER(interfaces, i -> regexp_like(i, '^wallet_'))) > 0`
9. **Change-log tables:** No row = no change. Use `MAX_BY` for snapshots — see FORWARD_FILL below.
10. **Asset naming:** `'TON'` in balances_history vs `'0:000...000'` in external_balances — normalize when merging.
11. **`code_hash` classifies unlabeled contracts.** Nominator pools, vesting, multisig — all identifiable by code_hash. See Code Hash Reference below.
12. **All addresses in Dune are RAW UPPERCASE.** Always use `UPPER('0:b113a994...')` in WHERE clauses, or write addresses in uppercase directly.

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

## ADDRESS_CLASSIFICATION (13 Categories)

Priority-based CASE — first match wins. Uses labels + code_hash + first_tx_sender.

```sql
, CLASSIFIED AS (
    SELECT A.address, A.balance / 1e9 AS ton_balance,
        CASE
            WHEN L.label = 'ton_believers'          THEN 'TON Believers Fund'
            WHEN L.label = 'frozen_early_miner'     THEN 'Frozen Early Miners'
            WHEN A.address = '-1:3333333333333333333333333333333333333333333333333333333333333333'
                                                    THEN 'Staked TON (Elector)'
            WHEN A.code_hash IN (
                'qLqO8gLwVoLiBAOD2HQ09A5JaFjHp7YvJ6rPJyHKJdM=',  -- Nominator Pool
                'Nn28aMPb0QNgfzGKlUqiVFV9AzHbfQPkh7JV0XQdCl4=',  -- Single Nominator
                'FTbVVlhZPWfXM0jVj+tGlRSqBM7hpKNUBCKBKHEBB3k=',
                'qADUcXRRa2xFz7mHyqkO5FpDq0z8G4hVHn0fqJbmvMo=',
                '/8YR8NvOlrOGNhMKEeIJjULGqDNKL8neFMQNE/Y36sc='
            )                                       THEN 'Staked TON (Nominator Pools)'
            WHEN L.label = 'telegram'               THEN 'Telegram'
            WHEN L.label = 'ton_ecosystem_reserve'  THEN 'TON Ecosystem Reserve'
            WHEN L.category = 'CEX'                 THEN 'CEX'
            WHEN A.first_tx_sender IN (
                '0:1150B518E7A3B0B9D55E27A8EFAB0C282F6A7C96FC926E6F0F0EEEDB3A7ECA3',
                '0:FB3D4D1B68FDC2CE68C4E14C26D0DC58EA5C1DF6076DBC7C4C1A2A0A2A0A2A0A',
                '0:A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D7E8F9A0B1',
                '0:F61C2F88A05CE41E5FA4C987A57CA64E87C8DB90BB1C0D76E92B96F5C0FA1001'
            )                                       THEN 'Other DeFi'
            WHEN L.category IN ('dex','defi','lending','bridge','liquid-staking')
                                                    THEN 'Other DeFi'
            WHEN A.code_hash = 'p6Jhak1jmgdsL2fnzOBCP9Khwu5VCtZRwe2hbuE7yso='
                                                    THEN 'Other Apps'
            WHEN L.address IS NOT NULL              THEN 'Other Apps'
            WHEN A.code_hash IN (
                'tmwWMMOfpn8drtI2tSrzzp5nVEFhtDczdei07vG8vFk=',
                'tItTGr7DtxRjgpH3137W3J9qJynvyiBHcTc3TUrotZA=',
                'iPv4GOR9XzKPfcNLrUMjuyihLsbHXOnsJdd3RsVuHe0='
            )                                       THEN 'Other Vesting / Lockers'
            WHEN A.code_hash = '09FNqaYn8Ow1MzQYKXYq+SuVQLIb8DZl+sCcK0bqu6w='
                                                    THEN 'Other Multisig Wallets'
            WHEN cardinality(FILTER(A.interfaces, i -> regexp_like(i, '^wallet_'))) > 0
                                                    THEN 'Other Wallets'
            WHEN A.status = 'uninit'                THEN 'Never Used Addresses (uninit)'
            ELSE 'Other Smart Contracts'
        END AS holder_type
    FROM ton.accounts A
    LEFT JOIN LABELS L ON A.address = L.address
    WHERE A.balance > 0
)
```

## BALANCE_TIERS

7-tier whale classification (log-10 steps, industry standard):

```sql
CASE
    WHEN ton_balance >= 10000000 THEN 'Humpback (>10M)'
    WHEN ton_balance >= 1000000  THEN 'Whale (1M-10M)'
    WHEN ton_balance >= 100000   THEN 'Shark (100K-1M)'
    WHEN ton_balance >= 10000    THEN 'Fish (10K-100K)'
    WHEN ton_balance >= 1000     THEN 'Crab (1K-10K)'
    WHEN ton_balance >= 10       THEN 'Shrimp (10-1K)'
    ELSE 'Dust (<10)'
END AS balance_tier
```

## FORWARD_FILL (MAX_BY)

Both `ton.balances_history` and `result_external_balances_history` are change-logs. To get balance on date X, find the latest row where `block_date <= X`:

```sql
-- Monthly snapshot: balance from the last change within each month
, BALANCE_UPDATES AS (
    SELECT DATE_TRUNC('month', block_date) AS month, address, asset,
           MAX_BY(amount, block_date) AS amount
    FROM ton.balances_history
    GROUP BY 1, 2, 3
)
```

## Code Hash Reference

| code_hash (base64) | Type | Count | TON (M) |
|---------------------|------|-------|---------|
| `qLqO8gLwVoLiBAOD2HQ09A5JaFjHp7YvJ6rPJyHKJdM=` | Nominator Pool | — | — |
| `Nn28aMPb0QNgfzGKlUqiVFV9AzHbfQPkh7JV0XQdCl4=` | Single Nominator | — | — |
| `FTbVVlhZPWfXM0jVj+tGlRSqBM7hpKNUBCKBKHEBB3k=` | Nominator variant | — | — |
| `qADUcXRRa2xFz7mHyqkO5FpDq0z8G4hVHn0fqJbmvMo=` | Nominator variant | — | — |
| `/8YR8NvOlrOGNhMKEeIJjULGqDNKL8neFMQNE/Y36sc=` | Nominator variant | — | — |
| `tmwWMMOfpn8drtI2tSrzzp5nVEFhtDczdei07vG8vFk=` | Vesting lock | ~633 | ~29.1 |
| `tItTGr7DtxRjgpH3137W3J9qJynvyiBHcTc3TUrotZA=` | Teleswap lock | — | — |
| `iPv4GOR9XzKPfcNLrUMjuyihLsbHXOnsJdd3RsVuHe0=` | Other lockers | — | — |
| `09FNqaYn8Ow1MzQYKXYq+SuVQLIb8DZl+sCcK0bqu6w=` | Multisig | ~1,694 | ~6.9 |
| `p6Jhak1jmgdsL2fnzOBCP9Khwu5VCtZRwe2hbuE7yso=` | NFT auction | — | — |

Discover new hashes:
```sql
SELECT code_hash, COUNT(*) AS cnt, SUM(balance/1e9) AS ton
FROM ton.accounts
WHERE balance > 0 AND code_hash IS NOT NULL
  AND address NOT IN (SELECT address FROM dune.ton_foundation.dataset_labels)
GROUP BY 1 ORDER BY ton DESC LIMIT 50
```

## SQL Conventions

- **CTE naming:** UPPER_SNAKE_CASE (`REAL_USERS`, `ALL_LABELS`)
- **WHERE:** `WHERE 1=1` then `AND` for each filter (easy to comment/uncomment)
- **Partition pruning:** Always filter `block_date` early — critical for performance
- **Message filtering:** `direction = 'in' AND NOT bounced`
- **TON conversion:** `/ 1e9` for nanoton to TON
- **Addresses:** Raw format (`0:...`) everywhere. Friendly (UQ/EQ) only via `ton_address_raw_to_user_friendly()`
- **Clickable links in Dune:** `GET_HREF(url, display_text)`
- **Engine:** Presto SQL (Dune) — Trino syntax
- **Array filtering:** `cardinality(FILTER(interfaces, i -> regexp_like(i, '^wallet_.*'))) > 0`
