# Changelog

## 0.2.0 — 2026-03-18

### Added
- `CHANGELOG.md` — track what changes between releases
- `setup` script — idempotent install (symlink + optional env check)
- GitHub Actions CI — validates manifest, reference links, skill structure
- `fragment-username-sales.sql` example
- Fragment outflow classification with TONAPI-verified opcodes
- `dex_trades` schema with all columns and TON token addresses
- NFT tables, Fragment payment classification, and SQL gotchas

### Changed
- Version bump: 0.1.0 → 0.2.0
- Fragment outflow labels: Rewards → Cashout, simplified gas opcodes

### Fixed
- `dex_trades` schema: added missing columns, removed non-existent `symbol` column
- `payment_asset=TON` filter warning for NFT volume queries
- Direction filter explanation in patterns.md

## 0.1.0 — 2026-02-12

### Added
- Initial release
- SKILL.md with trigger-based activation
- Reference files: tables, labels, patterns, dune-api, ton-blockchain, tonapi
- 7 battle-tested SQL examples (supply breakdown, real wallets, net value flow, NFT names, trace fees, filter interfaces)
- Marketplace registration
- Lazy-loaded reference architecture
