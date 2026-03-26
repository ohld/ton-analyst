# Vesting & Locker Analysis

How to analyze TON Believers Fund (TBF) and other vesting/locker contracts.

## TBF Contract Mechanics

- **Contract:** [locker-contract](https://github.com/ton-blockchain/locker-contract)
- **Lock period:** 2 years (Oct 2023 → Oct 2025)
- **Vesting:** 36 monthly payments after lock expires
- **APY:** ~7% (rewards deposited by external wallets, not from staking)

### Transaction Comments

| Comment | Meaning |
|---------|---------|
| `"d"` | Deposit — user locks TON |
| `"w"` | Withdraw — user claims unlocked TON |
| `"r"` | Reward — external wallet deposits APY reward |

Filter by comment in `ton.messages` to classify flows.

## Claim Rate Measurement

Not all unlocked TON gets claimed. Measure:

```
Claim rate = Actually withdrawn / Total unlockable
```

This is the key metric for estimating real sell pressure vs theoretical maximum.

## Destination Attribution

Use 4-hop ratio attribution (see [flow-tracing.md](flow-tracing.md)) to trace where withdrawn TON goes:

1. Direct CEX deposits (1-hop)
2. Staking (validator pools, liquid staking)
3. Held in wallets (check balance vs received — if balance > 90% of received, it's held)
4. DEX sells
5. Multi-hop CEX (2-4 hops through intermediaries)

### Forwarding Detection

Wallets with balance < 10% of total received are **forwarders** — trace one more hop. This catches intermediary wallets used for trace-breaking.

## Sell Pressure Estimation

```
Theoretical max sell pressure = Monthly unlock amount
Actual sell pressure = Claimed amount × CEX deposit rate
```

Actual is typically much lower than theoretical (historically ~12% claim rate × ~50% to CEX = ~6% of theoretical).

## Liquid Staking Gotcha

See [staking-analysis.md](staking-analysis.md) — deposits go to **pool contracts**, not jetton masters. Use `dataset_labels WHERE category = 'liquid-staking'` for detection.

## Related

- [flow-tracing.md](flow-tracing.md) — multi-hop ratio attribution
- [staking-analysis.md](staking-analysis.md) — liquid staking detection
- [cex-flows.md](cex-flows.md) — CEX destination classification
- [../dune/dashboards.md](../dune/dashboards.md) — Believers Fund dashboard
