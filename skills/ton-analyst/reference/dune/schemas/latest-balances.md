# ton.latest_balances

Current balance snapshot. Simpler than reconstructing from `balances_history`.

| Column | Type | Notes |
|--------|------|-------|
| address | string | |
| asset | string | Unique key: address + asset |
| amount | decimal(38,0) | Current balance (raw units) |
