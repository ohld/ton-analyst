# Staking Analysis

How to analyze validator staking, liquid staking, and unstaking behavior on TON.

## Elector Mechanics

Validators re-stake every ~18 hours. This means gross Elector volumes are **enormous** (tens of billions TON/month) while net flows are small (tens of millions). Always report net, not gross.

## Unstaking Destination Tracing

Most unstaking is **rotation** (validators moving between pools), not sell pressure:

1. Query Elector outflows for the period
2. Trace 3-hop from Elector → validators → pools → controllers → end destination
3. Classify destinations: staking rotation, CEX, held, vesting/multisig, DEX
4. Use `code_hash` from `ton.accounts` to identify contract types (nominator pools, vesting wallets, etc.)

**Key insight:** ~75% of unstaking goes back into staking (rotation). Only ~17% reaches CEX. Report actual sell pressure, not gross unstaking.

See [flow-tracing.md](flow-tracing.md) for the multi-hop ratio attribution technique.

## Liquid Staking Detection

**CRITICAL:** Users send TON to **pool contracts**, not jetton masters.

```
❌ tsTON jetton master address — this is the token issuer, NOT where deposits go
✅ dataset_labels WHERE category = 'liquid-staking' — 26 addresses, 6 protocols
```

Known protocols: TonStakers (tsTON), Bemo (stTON), Hipo (hTON), and others in `dataset_labels`.

## Cross-Chain APY Comparison Framework

When comparing staking yields across chains:

| Metric | What it means | Pitfall |
|--------|--------------|---------|
| Nominal APY | Headline staking return | Meaningless without inflation context |
| Inflation rate | Protocol token emission | Some chains are deflationary (BNB burns) |
| Real yield | Nominal APY - inflation | The only comparable metric |
| Staking ratio | % of supply staked | Affects yield (higher ratio → lower APY) |

Always compare **real yield** (nominal minus inflation), not headline APY. A 20% APY with 15% inflation is worse than 3% APY with 0.5% inflation.

## Pitfalls

- **Gross ≠ net.** Elector processes billions monthly. Net flow = millions.
- **Rotation ≠ selling.** Most unstaking is pool rebalancing.
- **Liquid staking pool ≠ master.** Deposits go to pool contracts.
- **Seasonal events.** Validator unstaking can spike around holidays (e.g., Christmas 2025).

## Related

- [cex-flows.md](cex-flows.md) — unstaking → CEX is a subset of CEX inflows
- [flow-tracing.md](flow-tracing.md) — multi-hop attribution technique
- [../ton/blockchain.md](../ton/blockchain.md) — Elector and staking basics
- [../dune/dashboards.md](../dune/dashboards.md) — Staking dashboard
