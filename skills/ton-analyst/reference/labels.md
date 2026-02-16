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

**WARNING:** `result_custodial_wallets` contains non-CEX wallets (Telegram wallets, bots). Always filter:
```sql
WHERE category = 'CEX'
  AND label NOT IN ('wallet_in_telegram', 'crypto_bot', 'xrocket', 'pocketbroker')
```

**Internal transfers:** ~42% of CEX deposit volume is CEX↔CEX shuffling. When counting real user deposits, exclude transfers where source is also custodial.

**Custodial wallets materialized view:** https://dune.com/queries/5032986 — how deposit wallets were identified.

### Verified CEX Custodial Addresses (from research)

These addresses were manually verified via flow tracing and are NOT in `dataset_labels`:

| CEX | Raw Address | Friendly | Source |
|-----|-------------|----------|--------|
| Bybit | `0:C23A1209B86A15AD9A2741CC11BB785EB3DD14BFFC8EA576ACC31BC24F801BB6` | UQDCOhIJ... | TBF Cluster A (22 wallets → single address) |
| OKX | `0:07AD2C78C5F14BE96A98DC14A736D7327031D12BF812678A21949B9389F872DC` | UQAHrSx4... | TBF withdrawal tracing |
| OKX | `0:D5F36BE44D8DC0ED6C13523298E0B317D7854034F1A1C1A9F75F2D95A6606F08` | UQDV82vk... | TBF withdrawal tracing |
| OKX | `0:1D4AC7CEE722C8B67D93909E4522164F5AA9A0DD03BDB2C4AC7CFA49470B4FF1` | UQAdSsfO... | TBF withdrawal tracing |
| Binance | `0:5889BC784635AEEA455FA787A7914824B95E17F08431A913B67B3E049B946CC8` | UQBYibx4... | TBF withdrawal (via intermediaries) |

## DeFi Gap

Many DeFi pool contracts are NOT in `dataset_labels`. Build DEFI_LABELS CTE from `result_dex_pools_latest` + `result_external_balances_history`. See reference/patterns.md for the full CTE.

## Sybil Wallets

`result_sybil_wallets` — ~153K addresses flagged as sybil/bot.

**Sybil wallets materialized view:** https://dune.com/queries/5206440 — how sybil addresses were identified.
