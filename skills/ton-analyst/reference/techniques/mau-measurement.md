# Active User Measurement

## Custodial Wallet Inflation

Approximately **half of new TON wallets** are custodial deposit addresses created by exchanges and payment providers (one wallet per user deposit, not reused). Similarly, ~1/3 of weekly active wallets are custodial. This is normal across all chains, but means raw wallet counts overstate real user numbers.

**Dashboard:** [TON Weekly](https://dune.com/ton_foundation/ton-weekly) — WAU and new users split by custodial vs non-custodial.
- [Query 5052073 / viz 8343735](https://dune.com/queries/5052073/8343735) — Weekly Active Users (custodial vs non-custodial)
- [Query 5052073 / viz 8343340](https://dune.com/queries/5052073/8343340) — New Active Users breakdown

## Measuring Per-Project MAU

Two-track approach depending on project type:

- **CEX projects:** count unique wallets in `result_cex_flows_daily` per exchange
- **Non-CEX:** join `ton.messages` with `dataset_labels`, count unique counterparty wallets

Exclude internal (contract-to-contract) messages. See [../ton/labels.md](../ton/labels.md) for label coverage.

**Caveats:** `ton.messages` only (no jettons/NFTs), unlabeled projects are invisible, DEX users may hit pool contracts not labeled to the DEX — use `result_dex_pools_latest` to fill gaps.
