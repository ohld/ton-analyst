# Materialized Views (result_* tables)

Pre-computed datasets maintained by TON Foundation on Dune. Refresh daily.

## Usage
All accessed via `dune.ton_foundation.result_TABLE_NAME`.

## Views

| Table | Description | Source Query | Rows (approx) |
|-------|-------------|-------------|----------------|
| result_custodial_wallets | CEX deposit addresses detected by transaction patterns | [Q5032986](https://dune.com/queries/5032986) | ~10.8M |
| result_cex_flows_daily | Daily CEX deposits/withdrawals per address | TBD | ~38M |
| result_sybil_wallets | Bot/sybil addresses | TBD | ~153K |
| result_nominators_cashflow | Staking deposit/withdrawal flows | TBD | — |
| result_nominators_balances | Current staking positions | TBD | — |
| result_dex_pools_daily | DEX pool metrics by day | TBD | — |
| result_dex_pools_latest | Current DEX pool state | TBD | — |
| result_external_balances_history | DeFi position changes | TBD | — |
| result_jetton_price_daily | Jetton prices | TBD | — |
| dataset_labels | Named entities (~3,150) | [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels) | ~3,150 |

### Gotchas
- `result_cex_flows_daily`: Safe for per-address CEX detection. WRONG for total market aggregation (inflates 2-3x). See ../techniques/cex-flows.md.
- `result_custodial_wallets`: Contains ALL custodial wallets, not just CEX. Filter `WHERE category = 'CEX'`.
- `dataset_labels`: category is never NULL. Tags field contains special flags like `has-custodial-wallets`.
