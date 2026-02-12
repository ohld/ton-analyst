-- Supply Breakdown by Holder Type (13 categories)
--
-- Question: How is TON supply distributed across holder types?
-- Uses: DEFI_LABELS + LABELS CTEs (see reference/patterns.md), ADDRESS_CLASSIFICATION CASE
-- Dashboard: https://dune.com/queries/6674371
--
-- TON Supply Facts (2026-02-11):
-- | Category                     | TON    | %   | Addresses |
-- | TON Believers Fund           | 1.3B   | 25% | 1         |
-- | Frozen Early Miners          | 1.1B   | 21% | 171       |
-- | Staked TON (Elector + Pools) | 974.7M | 19% | 1,798     |
-- | Other Wallets                | 583.8M | 11% | 26.6M     |
-- | Telegram                     | 327.2M | 6%  | 2         |
-- | TON Ecosystem Reserve        | 319.0M | 6%  | 3         |
-- | Never Used (uninit)          | 249.2M | 5%  | 9.2M      |
-- | CEX                          | 162.5M | 3%  | 6.1M      |
-- | Other Apps                   | 85.0M  | 2%  | 4.0M      |
-- | Other DeFi                   | 30.1M  | 1%  | 27K       |
-- | Other Vesting / Lockers      | 29.1M  | 1%  | 633       |
-- | Other Smart Contracts        | 16.0M  | <1% | 99M       |
-- | Other Multisig Wallets       | 6.9M   | <1% | 1,694     |

WITH _ AS (SELECT 1)

-- DEFI_LABELS and LABELS CTEs — see reference/patterns.md for reusable versions
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
        SELECT address, label, category FROM dune.ton_foundation.dataset_labels
    UNION ALL
        SELECT address, label, category FROM dune.ton_foundation.result_custodial_wallets
    UNION ALL
        SELECT * FROM DEFI_LABELS
)

-- Priority-based CASE — first match wins (see reference/patterns.md for ADDRESS_CLASSIFICATION)
, CLASSIFIED AS (
    SELECT A.address, A.balance / 1e9 AS ton_balance,
        CASE
            WHEN L.label = 'ton_believers'          THEN 'TON Believers Fund'
            WHEN L.label = 'frozen_early_miner'     THEN 'Frozen Early Miners'
            WHEN A.address = '-1:3333333333333333333333333333333333333333333333333333333333333333'
                                                    THEN 'Staked TON (Elector)'
            WHEN A.code_hash IN (
                'qLqO8gLwVoLiBAOD2HQ09A5JaFjHp7YvJ6rPJyHKJdM=',
                'Nn28aMPb0QNgfzGKlUqiVFV9AzHbfQPkh7JV0XQdCl4=',
                'FTbVVlhZPWfXM0jVj+tGlRSqBM7hpKNUBCKBKHEBB3k=',
                'qADUcXRRa2xFz7mHyqkO5FpDq0z8G4hVHn0fqJbmvMo=',
                '/8YR8NvOlrOGNhMKEeIJjULGqDNKL8neFMQNE/Y36sc=',
                'mj7BS8CY9rRAZMMFIiyuooAPF92oXuaoGYpwle3hDc8='
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

SELECT holder_type, COUNT(*) AS address_count,
       ROUND(SUM(ton_balance), 2) AS ton_balance,
       ROUND(SUM(ton_balance) / SUM(SUM(ton_balance)) OVER (), 2) AS pct_of_supply
FROM CLASSIFIED
GROUP BY holder_type
ORDER BY ton_balance DESC
