# Transaction Fee Analysis

TON fee structure and cross-chain comparison methodology.

## TON Fee Types

| Operation | Typical Cost (TON) | Typical Cost (USD) |
|-----------|--------------------|--------------------|
| Native transfer | 0.005 | ~$0.007 |
| Jetton transfer | 0.014-0.037 | ~$0.02 |
| DEX swap | 0.06-0.13 | ~$0.10 |
| Complex contract call | 0.06+ | ~$0.08+ |

TON uses a **deterministic fee model** — no fee market, no auction, no priority tips. Fees don't spike under congestion, unlike Ethereum or Solana.

## Cross-Chain Comparison Framework

When comparing fees across chains, always compare the **same operation type** (DEX swap is the standard benchmark):

| Tier | Examples | DEX Swap Cost |
|------|----------|---------------|
| Ultra-cheap | Avalanche, Polygon | $0.0001-$0.001 |
| Cheap | Solana, Base, Arbitrum | $0.002-$0.003 |
| Moderate | BNB, Cosmos, NEAR, Sui | $0.005-$0.01 |
| Expensive | TON, Ethereum L1 | $0.08-$0.10 |
| Very expensive | Tron | $2.00+ |

## Pitfalls

- **ETH L1 is anomalous in 2025-2026.** Gas prices dropped to ~0.048 Gwei, making L1 swaps temporarily cheaper than TON. This is likely temporary.
- **Tron fees post-August 2025 halving.** TRC-20 transfer to existing wallet: $2.01, to new wallet: $4.22. These are energy-based, not gas-based.
- **TON's fee stability is a feature.** Deterministic fees mean predictable costs for dApps and users. Highlight this when comparing.
- **USD cost depends on token price.** TON fees are denominated in TON. USD equivalents shift with price. Always note the price assumption.

## Agent Micropayment Context

For agent-to-agent payments (x402, micropayments):
- Native transfers ($0.007) — borderline acceptable
- Jetton transfers ($0.02) — too expensive for frequent operations
- On-chain logic ($0.08+) — impractical for per-request billing

## Related

- [../ton/blockchain.md](../ton/blockchain.md) — TON message passing model
- [../dune/dashboards.md](../dune/dashboards.md) — fee-related queries
