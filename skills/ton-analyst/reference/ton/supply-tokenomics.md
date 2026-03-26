# Supply & Tokenomics

TON supply structure, inflation mechanics, and common errors in official documentation.

## Supply Categories

| Category | How to Measure | Notes |
|----------|---------------|-------|
| Freely circulating | Total - locked - staked - frozen | The liquid market |
| Validator staking | Elector contract balance | ~18.6% of supply, cycles every 18h |
| Believers Fund | BF contract balance + claimed | See [vesting-analysis.md](../techniques/vesting-analysis.md) |
| Frozen inactive miners | 171 addresses, `status = 'frozen'` | Keys likely lost, governance freeze until ~Feb 2027 |
| Telegram vesting | Identified via `code_hash` in `ton.accounts` | 1440-day vesting, 360-day cliff |
| Liquid staking | `dataset_labels WHERE category = 'liquid-staking'` | Subset of total staking |

Use Dune query on `ton.latest_balance` + classification CTEs from [query-patterns.md](../dune/query-patterns.md) (ADDRESS_CLASSIFICATION).

## Inflation Mechanics

TON has **perpetual** block rewards (no halving, no end date). See [Elector source code](https://github.com/ton-blockchain/ton/blob/master/crypto/smartcont/elector-code.fc) for reward distribution logic.

| Component | Amount | Period |
|-----------|--------|--------|
| Masterchain reward | 1.7 TON/block | Per block |
| Basechain reward | 1.0 TON/block | Per block |
| Gross daily emission | ~97,000 TON | Daily |
| Fee burn | ~1,000-3,000 TON | Daily (varies) |
| Net new supply | ~94,000-96,000 TON | Daily |
| Annual inflation | ~0.7% of total supply | But ~1.4% of circulating |

**Important:** Inflation as % of total and % of circulating are very different because ~50% of supply is locked/frozen/staked.

## Frozen Miners

- **Count:** 171 addresses
- **Total:** ~1,081M TON (~21% of supply)
- **Status:** Frozen by [governance vote](https://t.me/tonblockchain/223) (Feb 21, 2023) for 48 months. See [Blockworks coverage](https://blockworks.co/news/ton-votes-to-freeze-inactive-mining-wallets), [Cointelegraph coverage](https://cointelegraph.com/news/ton-community-votes-burn-freeze-inactive-wallets)
- **Expected unlock:** ~Feb 2027 (requires another governance vote)
- **Keys likely lost:** Most addresses have never been active since mining ended. If keys are lost, these TON are effectively burned.

## Known Errors in Official Documentation

Corrections to commonly cited sources:

1. **"0.6% annual inflation"** — actually ~0.7% (depends on block time assumptions)
2. **BF start date** — lock started Oct 2023, NOT earlier dates sometimes cited
3. **"Telegram owns 327M TON"** — this counts only 2 main wallets. TG vesting contracts (identified by `code_hash`) are classified separately as "Other Vesting / Lockers" in most Dune queries
4. **DeFiLlama TVL** — their adapters may use incomplete address lists. Cross-verify with on-chain data.

## Pitfalls

- **"Telegram" supply is ambiguous.** Specify whether you mean 2 main wallets or 2 main + vesting contracts.
- **Inflation vs circulating.** Always specify denominator: % of total supply or % of circulating.
- **Frozen ≠ burned.** Frozen miners could theoretically unlock. Don't count them as burned.

See also: [vesting analysis](../techniques/vesting-analysis.md), [staking analysis](../techniques/staking-analysis.md), [ADDRESS_CLASSIFICATION CTE](../dune/query-patterns.md), [Dune dashboards](../dune/dashboards.md).
