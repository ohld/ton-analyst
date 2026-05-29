# TON Analyst Reference Index

Use this file to choose the smallest reference set before writing SQL or doing
wallet research.

## Common Routes

| Task | Read |
|------|------|
| TON or USDT balances | [dune/assets.md](dune/assets.md), [dune/schemas/balances.md](dune/schemas/balances.md) |
| Jetton transfers | [dune/assets.md](dune/assets.md), [dune/schemas/jetton-events.md](dune/schemas/jetton-events.md) |
| Dune SQL gotchas | [dune/query-patterns.md](dune/query-patterns.md) |
| Single wallet investigation | [ton/address-investigation.md](ton/address-investigation.md), [cli.md](cli.md) |
| CEX and custodial flows | [techniques/cex-flows.md](techniques/cex-flows.md) |
| Real-user filtering / MAU | [techniques/mau-measurement.md](techniques/mau-measurement.md) |
| Flow tracing | [techniques/flow-tracing.md](techniques/flow-tracing.md) |
| Trading bot adoption / fees | [techniques/trading-bot-adoption.md](techniques/trading-bot-adoption.md), [dune/examples/trading-bot-fee-adoption.sql](dune/examples/trading-bot-fee-adoption.sql), [dune/examples/trading-bot-query-id-dex-volume.sql](dune/examples/trading-bot-query-id-dex-volume.sql) |
| Staking | [techniques/staking-analysis.md](techniques/staking-analysis.md) |
| NFT / Fragment sales | [dune/schemas/nft-events.md](dune/schemas/nft-events.md) |
| Repeated mistakes | [local-learnings.md](local-learnings.md), then promote stable rules into the relevant reference |

## Maintenance Rule

When an analyst repeats the same mistake twice, do not leave the fix only in a
chat or PR comment. Add it to [local-learnings.md](local-learnings.md), then
promote it into the narrowest durable reference file.
