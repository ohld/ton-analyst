# ton.jetton_events

Jetton (token) transfer events.

| Column | Type | Notes |
|--------|------|-------|
| block_date | date | Partition key |
| source | string | Sender |
| destination | string | Receiver |
| jetton_master | string | Token contract address |
| amount | bigint | Raw units (check decimals per token) |
| tx_aborted | boolean | Filter with `tx_aborted = FALSE` |

**USDT on TON:** jetton_master = `0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE`, 6 decimals (divide by 1e6).
