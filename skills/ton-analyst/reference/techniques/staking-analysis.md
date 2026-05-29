# Staking Analysis

**Dashboard (source of truth):** [TON Staking](https://dune.com/ton_foundation/staking) — staking flows, nominator pools, APY.

## Elector Balance vs Staker Balances

The [Elector contract](https://github.com/ton-blockchain/ton/blob/master/crypto/smartcont/elector-code.fc) holds all staked TON. Validators re-stake every ~18 hours, so gross volumes are enormous (tens of billions TON/month) while net changes are small.

**Important distinction:** Elector balance = total staked. But individual staker balances (via nominator pool contracts) may not sum to the same number due to in-flight stakes, pending rewards, and timing differences between validation rounds. Use `result_nominators_cashflow` ([schema](../dune/schemas/messages.md)) for per-staker flows.

## Unstaking Destination Tracing

Most unstaking is **rotation** (validators moving between pools), not sell pressure. Methodology:

1. Query Elector outflows → trace 3-hop through validators → pools → controllers → destination
2. Classify by `code_hash` from `ton.accounts` ([code hash reference](../dune/patterns/address-classification.md))
3. ~75% = staking rotation, ~17% = CEX, rest = held/DEX/vesting

See [flow-tracing.md](flow-tracing.md) for multi-hop ratio attribution.

## Validator Attribution Rules

- Do not label a validator by funding origin alone. CEX, bridge, merchant, or other service funding is liquidity provenance, not ownership.
- Keep `@wallet` / Wallet in Telegram as an explicit exception only when it deploys or operates validators.
- Group validators/wallets only with independent on-chain links: shared deployers, mutual transfers, hop wallets, operational wallets, or repeated controller/pool relationships.
- For a single validator/account check, use `ton acc` and `ton tx` first. Use Dune for validator sets, historical rounds, multi-hop grouping, and time series.

## Cashflow Debug Columns

When maintaining native staking cashflow materialized views or queries, include trace/debug identifiers where possible: `trace_id`, `tx_hash`, `tx_lt`, and `msg_hash`. A sampled row should be cross-checkable against TONAPI/Tonviewer without reconstructing the query.

## Liquid Staking Detection

Users send TON to **pool contracts**, not jetton masters:

```
❌ tsTON jetton master — token issuer, NOT deposit target
✅ dataset_labels WHERE category = 'liquid-staking' — 26 addresses, 6 protocols
```

Protocols: [TonStakers](https://tonstakers.com) (tsTON), [Bemo](https://bemo.finance) (stTON), [Hipo](https://hipo.finance) (hTON).

## Cross-Chain APY Comparison

Always compare **real yield** (nominal APY minus inflation), not headline numbers. A 20% APY with 15% inflation is worse than 3% with 0.5%. Key variables: staking ratio (higher → lower APY), inflation model (perpetual vs halving), and whether the chain is deflationary (BNB burns).

## Future Work

Top stakers include unlabeled wallets — labeling them would improve flow attribution accuracy. See [address-investigation.md](../ton/address-investigation.md) for the labeling workflow.
