# MAU Measurement

How to measure Monthly Active Users for TON ecosystem projects using on-chain data.

## Two-Track Methodology

Different detection methods for different project types:

### Track 1: CEX Projects

Use `result_cex_flows_daily` materialized view (10.8M known deposit/withdrawal addresses). Count unique wallet addresses that deposited to or withdrew from each exchange in the period.

### Track 2: Non-CEX Projects

Join `ton.messages` with `dataset_labels` to find interactions with labeled project addresses. Count unique counterparty wallets.

```
MAU = COUNT(DISTINCT wallet) WHERE wallet interacted with project addresses in 30-day window
```

### Internal Transaction Exclusion

Exclude contract-to-contract interactions (internal messages). Only count transactions initiated by user wallets to avoid inflating counts with automated protocol operations.

## Caveats

- **TON messages only.** Jetton transfers and NFT operations are not captured in basic `ton.messages` queries. This undercounts DeFi and NFT project users.
- **Label completeness.** Unlabeled projects are invisible. MAU rankings are bounded by label coverage in `dataset_labels`.
- **Value > 0 filter.** Excluding zero-value transactions misses some interaction types (e.g., governance votes, state updates).
- **Single snapshot.** This methodology gives a point-in-time view, not a rolling average. Run monthly for trends.
- **DeFi pool gap.** DEX users may interact with pool contracts that aren't labeled to the DEX. Use `result_dex_pools_latest` to fill this gap.

## Validation

Cross-check results against:
- Public bot statistics (Telegram bot MAU via BotFather)
- Exchange-reported user counts (where available)
- DEX frontend analytics (StonFi/DeDust public stats)

## Related

- [cex-flows.md](cex-flows.md) — CEX address detection
- [../dune/schemas/messages.md](../dune/schemas/messages.md) — messages table structure
- [../ton/labels.md](../ton/labels.md) — label categories and coverage
- [../dune/dashboards.md](../dune/dashboards.md) — ecosystem dashboards
