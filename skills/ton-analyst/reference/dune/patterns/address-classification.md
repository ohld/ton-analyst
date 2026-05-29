# Address Classification CTEs

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
                'qLqO8gLwVoLiBAOD2HQ09A5JaFjHp7YvJ6rPJyHKJdM=',  -- Nominator Pool (basechain)
                'Nn28aMPb0QNgfzGKlUqiVFV9AzHbfQPkh7JV0XQdCl4=',  -- Single Nominator
                'FTbVVlhZPWfXM0jVj+tGlRSqBM7hpKNUBCKBKHEBB3k=',
                'qADUcXRRa2xFz7mHyqkO5FpDq0z8G4hVHn0fqJbmvMo=',
                '/8YR8NvOlrOGNhMKEeIJjULGqDNKL8neFMQNE/Y36sc=',
                'mj7BS8CY9rRAZMMFIiyuooAPF92oXuaoGYpwle3hDc8='   -- Masterchain validation nominator pool
            )
                OR cardinality(FILTER(A.interfaces, i -> i = 'validation_nominator_pool')) > 0
                                                    THEN 'Staked TON (Nominator Pools)'
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
| `mj7BS8CY9rRAZMMFIiyuooAPF92oXuaoGYpwle3hDc8=` | Masterchain validation nominator pool | — | — |
| `p6Jhak1jmgdsL2fnzOBCP9Khwu5VCtZRwe2hbuE7yso=` | NFT auction | — | — |

Discover new hashes:
```sql
SELECT code_hash, COUNT(*) AS cnt, SUM(balance/1e9) AS ton
FROM ton.accounts
WHERE balance > 0 AND code_hash IS NOT NULL
  AND address NOT IN (SELECT address FROM dune.ton_foundation.dataset_labels)
GROUP BY 1 ORDER BY ton DESC LIMIT 50
```
