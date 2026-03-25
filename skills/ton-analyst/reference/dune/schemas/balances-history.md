# ton.balances_history

Records every **change** in balance. Change-log format, NOT snapshots.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | **Partition key** |
| block_time | timestamp | |
| address | string | Raw format |
| asset | string | `'TON'` for native, jetton_master address for jettons |
| amount | decimal(38,0) | Balance AFTER the change (raw units) |

**Critical:** No row = no change that day. Use `MAX_BY(amount, block_date)` for snapshots. See ../query-patterns.md for forward-fill.

**Asset naming gotcha:** Native TON = `'TON'` here, but `'0:000...000'` in `result_external_balances_history`. Normalize when merging:
```sql
CASE WHEN asset = 'TON'
    THEN '0:0000000000000000000000000000000000000000000000000000000000000000'
    ELSE asset
END AS asset
```
