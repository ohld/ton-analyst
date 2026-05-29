# ton.jetton_events

Jetton (token) transfer events.

For canonical USDT address formats and balance snippets, see
[../assets.md](../assets.md).

| Column | Type | Notes |
|--------|------|-------|
| block_time | timestamp | |
| block_date | date | Partition key |
| trace_id | string | Join key for trace-level attribution |
| query_id | decimal(20,0) | TON message query id; useful for bot/app attribution |
| source | string | Sender |
| destination | string | Receiver |
| jetton_master | string | Token contract address |
| amount | bigint | Raw units (check decimals per token) |
| tx_aborted | boolean | Filter with `tx_aborted = FALSE` |
| comment | string | Human-readable transfer comment, when present |

**Canonical USDT on TON:** `jetton_master = '0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE'`, 6 decimals (divide by `1e6`). Do not filter by symbol.
