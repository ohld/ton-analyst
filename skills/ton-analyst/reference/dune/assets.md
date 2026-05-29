# TON Asset Constants

Read this before writing balance, price, or jetton-transfer queries for core
assets. Do not rediscover these constants from scratch.

## Native TON

| Context | Value |
|---------|-------|
| Human asset | TON |
| Dune `ton.latest_balances.asset` | `'TON'` |
| Dune `ton.balances_history.asset` | `'TON'` |
| Dune `ton.accounts.balance` | raw nanoTON |
| Dune `ton.messages.value` | raw nanoTON |
| Display units | divide raw amount by `1e9` |
| DeFi external-balances native key | `0:0000000000000000000000000000000000000000000000000000000000000000` |

Native TON has no jetton master contract. Use the zero raw address only where a
specific table documents it, such as `result_external_balances_history`.

## Canonical USDT

| Context | Value |
|---------|-------|
| Human asset | USDT / Tether USD on TON |
| Raw jetton master | `0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE` |
| Hex account id | `B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE` |
| Bounceable user-friendly | `EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs` |
| Non-bounceable user-friendly | `UQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_p0p` |
| Dune balance asset | same raw jetton master |
| Dune `ton.jetton_events.jetton_master` | same raw jetton master |
| Decimals | 6 |
| Display units | divide raw amount by `1e6` |

Do not filter canonical USDT by `symbol = 'USDT'`; spam jettons often reuse the
same symbol. Filter by the raw jetton master.

## Balance Snippet

```sql
SELECT
    address,
    SUM(CASE
        WHEN asset = 'TON'
        THEN CAST(amount AS DOUBLE) / 1e9
        ELSE 0
    END) AS ton_balance,
    SUM(CASE
        WHEN asset = '0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE'
        THEN CAST(amount AS DOUBLE) / 1e6
        ELSE 0
    END) AS usdt_balance
FROM ton.latest_balances
WHERE asset IN (
    'TON',
    '0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE'
)
GROUP BY 1
```

## Jetton Transfer Snippet

```sql
SELECT
    block_date,
    source,
    destination,
    CAST(amount AS DOUBLE) / 1e6 AS usdt_amount
FROM ton.jetton_events
WHERE block_date >= DATE '2026-01-01'
    AND tx_aborted = false
    AND jetton_master = '0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE'
```

## Price Gotcha

`ton.prices_daily.price_usd` is per raw unit. For USD valuation, multiply raw
amount by `price_usd`. Do not divide to display units first and then multiply by
the raw-unit price.
