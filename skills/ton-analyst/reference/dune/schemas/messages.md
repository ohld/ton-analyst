# ton.messages

All messages (transactions) on TON.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | **Partition key** — always filter for pruning |
| block_time | timestamp | Use for `date_trunc('hour', ...)`. Use `block_date` for range filters |
| tx_hash | string | |
| trace_id | string | |
| direction | string | `'in'` or `'out'` |
| source | string | Raw address |
| destination | string | Raw address |
| value | bigint | Nanotons (divide by 1e9) |
| opcode | int | 260734629 = jetton internal transfer |
| bounced | boolean | Filter with `NOT bounced` |
| comment | string | Human-readable comment (NULL when absent) |
| fwd_fee | bigint | Forward fee |

**CRITICAL — always filter `direction = 'in'` when aggregating.** TON uses async message-passing: a transaction has 1 incoming message and may produce outgoing messages that trigger further transactions (all sharing the same `trace_id`). The `ton.messages` table stores both `direction='in'` and `direction='out'` rows. Without filtering, SUMs and COUNTs will be inflated. See ../ton/blockchain.md for the full execution model.

**Standard filter:** `WHERE direction = 'in' AND NOT bounced AND block_date >= DATE '2025-01-01'`

## Related Materialized Views (Staking)

### dune.ton_foundation.result_nominators_cashflow

Staking deposit/withdrawal flows for nominator pools.

| Column | Type | Notes |
|--------|------|-------|
| user_address | string | |
| value | bigint | Nanotons |
| direction | string | `'in'` (deposit) or `'out'` (withdrawal) |

Source query: [Q5755981](https://dune.com/queries/5755981)

Related dashboard: [TON Staking](https://dune.com/ton_foundation/staking)
