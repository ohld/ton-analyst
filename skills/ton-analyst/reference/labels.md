# Labels, Key Addresses & Entity Classification

## Label Source

[ton-studio/ton-labels](https://github.com/ton-studio/ton-labels/) — public repo, orgs/apps only (not individual people).

## dataset_labels Categories

~3,150 labeled addresses across 17 categories:

| Category | Count | | Category | Count |
|----------|-------|-|----------|-------|
| gaming | 1,183 | | CEX | 643 |
| merchant | 342 | | other | 217 |
| dex | 160 | | scammer | 113 |
| infrastructure | 86 | | bridge | 63 |
| lending | 56 | | liquid-staking | 37 |
| defi | 31 | | launchpad | 22 |
| social | 11 | | nft-marketplace | 10 |
| governance | 9 | | farming | 6 |
| media | 5 | | | |

**`category` is NEVER NULL.** No COALESCE needed.

## Key Addresses

**All addresses in Dune are RAW UPPERCASE.** Use these values directly in SQL WHERE clauses.

| Entity | Address | TON (M) |
|--------|---------|---------|
| TON Believers Fund | `0:ED1691307050047117B998B561D8DE82D31FBF84910CED6EB5FC92E7485EF8A7` | 1,301 |
| Elector (staking) | `-1:3333333333333333333333333333333333333333333333333333333333333333` | 962 |
| Telegram #1 | `0:8C397C43F9FF0B49659B5D0A302B1A93AF7CCC63E5F5C0C4F25A9DC1F8B47AB3` | 327 |
| TON Ecosystem Reserve | `0:66CD6E30625156D2D881823E6C3F50A04A52DD62CF95A633D633BA0F60F61640` | 281 |
| USDT Jetton Master | `0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE` | — |

## Key Labels for Supply Analysis

| Label | TON (M) | Category |
|-------|---------|----------|
| `ton_believers` | 1,301 | — |
| `frozen_early_miner` | 1,081 | — |
| `telegram` | 327 | — |
| `ton_ecosystem_reserve` | 319 | — |

**Early miners:** status=`uninit` (NOT `frozen`). Label=`frozen_early_miner`.

## CEX Infrastructure

CEX = Exchange main wallets + Custodial deposit wallets. Always combine both.

1. **Main wallets** — `dataset_labels` where `category = 'CEX'` (~643 addresses, ~127M TON)
2. **Deposit wallets** — `result_custodial_wallets` (~10.8M addresses, ~35M TON)

**WARNING:** `result_custodial_wallets` contains non-CEX wallets (Telegram wallets, bots). Always filter `WHERE category = 'CEX'`.

**Internal transfers:** ~42% of CEX deposit volume is CEX↔CEX shuffling. When counting real user deposits, exclude transfers where source is also custodial.

**Custodial wallets materialized view:** https://dune.com/queries/5032986 — how deposit wallets were identified.

## DeFi Gap

Many DeFi pool contracts are NOT in `dataset_labels`. Build DEFI_LABELS CTE from `result_dex_pools_latest` + `result_external_balances_history`. See reference/patterns.md for the full CTE.

## Sybil Wallets

`result_sybil_wallets` — ~153K addresses flagged as sybil/bot.

**Sybil wallets materialized view:** https://dune.com/queries/5206440 — how sybil addresses were identified.

## NFT Marketplace Addresses

From `dataset_labels` where `category='merchant'`.

| Marketplace | Address | sale_type | Notes |
|-------------|---------|-----------|-------|
| Fragment | `0:408DA3B28B6C065A593E10391269BAAA9C5F8CAEBC0C69D9F0AABBAB2A99256B` | auction | Primary auctions + resale auctions. 5% fee. |
| Getgems | `0:584EE61B2DFF0837116D0FCB5078D93964BCBE9C05FD6A141B1BFCA5D6A43E18` | sale/auction | Main secondary marketplace |
| Marketapp | `0:9A9CB80ADFBD1662F5108766D73355AC2C03304FDA1D25A479670E34EFCD72B3` | sale | NFT aggregator (marketapp.ws) |

## Telegram Official NFT Collections

| Collection | Address | Notes |
|------------|---------|-------|
| Telegram Usernames | `0:80D78A35F955A14B679FAA887FF4CD5BFC0F43B4A4EEA2A7E6927F3701B273C2` | @handles. Still actively minted via Fragment auctions. |
| Anonymous Telegram Numbers | `0:0E41DC1DC3C9067ED24248580E12B3359818D83DEE0304FABCF80845EAFAFDB2` | +888 numbers. All 136K minted Dec 2022. Now 100% secondary market. |
| TON DNS Domains | `0:B774D95EB20543F186C06B371AB88AD704F7E256130CAF96189368A7D0CB6CCF` | .ton domains |

## Fragment Sale Mechanics

- Fragment primary sales ARE captured in `ton.nft_events` as `type='sale'`, `sale_type='auction'`
- Mint events (`type='mint'`) have no sale_price — sale fires separately
- Fragment takes 5% marketplace fee (visible in `marketplace_fee` column)
- Telemint contracts: github.com/TelegramMessenger/telemint
- Primary vs secondary: use `ROW_NUMBER() OVER(PARTITION BY nft_item_address ORDER BY block_time) = 1` for first sale
