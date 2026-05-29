# Labels Router

Use this page to choose the narrow entity-label reference before writing SQL or classifying addresses.

## Routes

| Need | Read |
|------|------|
| Label source, dataset categories, major supply addresses, CEX infrastructure, sybil wallets | [key-addresses.md](key-addresses.md) |
| Fragment marketplace, Telegram NFT collections, gift operations, username auctions | [fragment.md](fragment.md) |
| How to investigate and submit new labels | [label-submission.md](label-submission.md) |
| Address-level investigation workflow | [wallet-investigation.md](wallet-investigation.md) |

## Core Rules

- `dataset_labels.category` is never NULL.
- `result_custodial_wallets` is not just CEX; filter `category = 'CEX'` for exchange deposit wallets.
- Fragment should be found with `label = 'fragment'`, not fuzzy name matching.
