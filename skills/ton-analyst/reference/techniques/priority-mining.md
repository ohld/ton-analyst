# TON Priority Mining / MEV

TON has no Ethereum-style gas auction, but traders can still get priority by
mining favorable message hashes. In TON message import is ordered by logical
time; when messages tie, the smaller hash is imported first. Bots can vary a
message until its hash is unusually low, then submit it during an arbitrage or
sandwich race.

Reference dashboard: [TON DEX traders smart-contract evolution](https://dune.com/pshuvalov/ton-traders-types-analysis)
by `pshuvalov`. Key queries: [Q5068564](https://dune.com/queries/5068564),
[Q5178836](https://dune.com/queries/5178836), [Q5471074](https://dune.com/queries/5471074).

## Detection Core

`ton.messages.msg_hash` is base64. For random hashes, the top bit should be
`1` about half the time. Priority mining for lower hashes pushes this share
toward `0`.

```sql
AVG(bitwise_right_shift(varbinary_to_uint256(from_base64(M.msg_hash)), 255))
    AS high_bit_share
```

Dashboard threshold:

```sql
trades_count > 20 AND high_bit_share < 0.20
```

Join DEX trades to root outbound messages:

```sql
FROM ton.dex_trades T
JOIN ton.messages M
  ON M.block_date = T.block_date
 AND M.trace_id = M.tx_hash
 AND M.tx_hash = T.trace_id
 AND M.direction = 'out'
```

This is a signal, not proof. It samples only one hash bit and root transactions
can emit multiple outbound messages. Use it for screening, then inspect traces.

## Trader Type

Classify traders from `ton.accounts.interfaces`:

```sql
CASE
  WHEN cardinality(FILTER(A.interfaces, i -> regexp_like(i, '.*highload.*'))) > 0
    THEN 'highload wallet'
  WHEN cardinality(FILTER(A.interfaces, i -> regexp_like(i, '^wallet_.*'))) > 0
    THEN 'wallet'
  ELSE 'other smart contracts'
END
```

Do not treat `wallet_highload_*` as MEV by itself. It is a throughput tool.

## Bot Deployer Pattern

For a suspected withdrawal/deployer wallet:

```sql
WITH deployed AS (
  SELECT address, code_hash, deployment_at
  FROM ton.accounts
  WHERE first_tx_sender = '0:RAW_TARGET'
)
SELECT D.code_hash, COUNT(*) bots, COUNT(T.trader_address) dex_active
FROM deployed D
LEFT JOIN ton.dex_trades T
  ON T.trader_address = D.address
 AND T.block_date >= CURRENT_DATE - INTERVAL '14' DAY
GROUP BY 1
ORDER BY dex_active DESC
```

Then join `ton.messages` between the target and deployed set to estimate bot
funding, withdrawals, and net TON returned to the target.

## Case Study

Wallet `UQCgeLdGoinbZ1Q0iraUXKqm23Q2kQGiOUK2Fih4bBEKmPwr`
(`0:A078B746A229DB6754348AB6945CAAA6DB74369101A23942B61628786C110A98`)
looks like a withdrawal/deployer wallet. In a 14-day Dune check on May 14, 2026:

- `0:DAE76200D29691C4D8571F6B9F97229C1EF2E33CA59A6EA69E37922E7B953D14`:
  38.7K DEX trades, $7.32M volume, ~48.9K TON net returned to target.
- `0:DAEE4C41201883B2F5D9E5E3A3A8FCB6FF988EE28F13978DF4CB2D0BA662C3B5`:
  9.6K DEX trades, $1.32M volume, ~6.2K TON net returned to target.
- The target also sent ~63.9K TON to `tonstakers`, so bot profits may be parked
  in liquid staking rather than kept in the withdrawal wallet.
