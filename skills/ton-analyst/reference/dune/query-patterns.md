# Reusable SQL Patterns

Start here, then load only the narrow file needed for the current query.

## Topic Routes

| Need | Read |
|------|------|
| Repeated TON/Dune mistakes before writing SQL | [patterns/gotchas.md](patterns/gotchas.md) |
| Real-user filtering, labels, DeFi label gap, counterparty filters | [patterns/labels-real-users.md](patterns/labels-real-users.md) |
| Supply holder categories, balance tiers, code hashes | [patterns/address-classification.md](patterns/address-classification.md) |
| NFT sales volume and Fragment asset classification snippets | [patterns/nft-fragment.md](patterns/nft-fragment.md) |
| Query style, partition pruning, Dune `GET_HREF` links | [patterns/sql-conventions.md](patterns/sql-conventions.md) |
| Transaction comment discovery and cross-validation | [patterns/comment-analysis.md](patterns/comment-analysis.md) |

## Domain-Specific References

- CEX flow analysis: [../techniques/cex-flows.md](../techniques/cex-flows.md)
- Multi-hop tracing: [../techniques/flow-tracing.md](../techniques/flow-tracing.md)
- Real-user / MAU work: [../techniques/mau-measurement.md](../techniques/mau-measurement.md)
- Staking analysis: [../techniques/staking-analysis.md](../techniques/staking-analysis.md)
- Trading-bot adoption: [../techniques/trading-bot-adoption.md](../techniques/trading-bot-adoption.md)
- Priority mining / TON MEV: [../techniques/priority-mining.md](../techniques/priority-mining.md)
