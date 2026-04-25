# ton-analyst

Claude Code skill for TON blockchain data analysis on [Dune Analytics](https://dune.com).

## What it does

- Generates Dune SQL queries for TON on-chain analysis
- Executes queries via Dune API and analyzes results
- Covers supply distribution, wallet analysis, token flows, DeFi activity, staking, CEX flows
- Includes battle-tested SQL patterns for 13-category supply classification, real user filtering, whale tiers

## Install

In Claude Code, run:

```
/plugin marketplace add ohld/ton-analyst
/plugin install ton-analyst@ohld-ton-analyst
```

This adds the repo as a marketplace source and installs the skill. Auto-updates are enabled by default — you'll get new patterns and fixes as they're pushed.

## Quick start

After installing, ask Claude Code:

> "What is the current TON supply breakdown by holder type?"

> "How many real wallets hold 10K+ TON over time?"

> "Show me net value flows between Binance and DeDust in the last 30 days"

The skill provides table schemas, reusable CTEs, and SQL conventions so Claude can generate correct queries on the first try.

## `ton` CLI — context-efficient TONAPI wrapper

Ships alongside the skill. Replaces the common `curl https://tonapi.io/... | python3 -c "..."` pattern with a single command that outputs terse TSV and aggressively prunes heavy technical fields (bytecode, phases, state updates, fees). Typical `ton tx` call returns ~80× less data than the raw TONAPI response.

```
ton acc <addr>                    address, label, status, balance_ton, flags, top_jettons
ton tx  <addr> [--out/--in/--min-value/--since/--before/--dest/--limit/--before-lt/--json]
```

Install (one command, creates a venv and drops a wrapper at `~/.local/bin/ton`):

```
./skills/ton-analyst/setup
```

Python 3.10+, deps = `httpx` + `pytoniq-core`. Optional env: `TONAPI_API_KEY` (higher rate limits), `TON_LABELS_CACHE` (default `~/.cache/ton-labels`). Full reference: [`skills/ton-analyst/reference/cli.md`](skills/ton-analyst/reference/cli.md). Future subcommand ideas: [`skills/ton-analyst/bin/TODO.md`](skills/ton-analyst/bin/TODO.md).

## What's inside

```
skills/ton-analyst/
├── SKILL.md                    # Entry point — capabilities, CLI, key tables
├── bin/
│   ├── ton                     # the CLI
│   └── TODO.md                 # deferred subcommand ideas
├── setup                       # venv + wrapper installer
├── requirements.txt            # httpx, pytoniq-core (runtime)
├── requirements-dev.txt        # + pytest, pytest-asyncio
├── tests/                      # pytest suite (35 tests, httpx.MockTransport — no network)
└── reference/
    ├── cli.md                  # `ton` CLI reference
    ├── tables.md               # Table schemas (12 tables)
    ├── labels.md               # Labels, key addresses, CEX, sybil
    ├── patterns.md             # Gotchas, reusable CTEs, classification logic
    ├── dune-api.md             # API docs, research workflow
    ├── ton-blockchain.md       # TON concepts, address formats, staking
    └── examples/               # Battle-tested SQL queries
        ├── README.md           # Index of examples
        ├── supply-breakdown.sql
        ├── real-wallets-ton.sql
        ├── real-wallets-usdt.sql
        ├── net-value-flow.sql
        ├── nft-names.sql
        ├── trace-fees.sql
        └── filter-interfaces.sql
```

## Key tables covered

- `ton.accounts`, `ton.messages`, `ton.balances_history`, `ton.jetton_events`
- `ton.prices_daily`, `ton.dex_trades`, `ton.latest_balances`
- `dune.ton_foundation.dataset_labels` — named entities (~3,150)
- `dune.ton_foundation.result_custodial_wallets` — CEX deposit wallets (~9.6M)
- `dune.ton_foundation.result_external_balances_history` — DeFi positions
- `dune.ton_foundation.result_sybil_wallets`, `result_nominators_cashflow`

## Local Development

1. Clone the repo
2. Install locally — either:
   - `claude --plugin-dir ./path/to/ton-analyst` (per-session), or
   - Symlink: `ln -s /path/to/ton-analyst/skills/ton-analyst ~/.claude/skills/ton-analyst`
3. Edit files in `skills/ton-analyst/`
4. Test: open Claude Code and ask a TON-related question — verify your changes are picked up
5. Submit a PR with your changes

### What to contribute

- New SQL examples — add `.sql` file in `reference/examples/`
- New table schemas or gotchas — edit `reference/tables.md` or `reference/patterns.md`
- New labels or address discoveries — edit `reference/labels.md`
- Bug fixes in existing SQL — edit the relevant file

## Resources

- [Dune TON Tables Overview](https://docs.dune.com/data-catalog/ton/overview)
- [TON Documentation](https://docs.ton.org/)
- [TON Verticals Dashboard](https://dune.com/ton_foundation/verticals)
- [Dune Spellbook — TON models](https://github.com/duneanalytics/spellbook/tree/main/dbt_subprojects/daily_spellbook/models/ton)
- [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels/) — address labels source
- [TON On-Chain Data Analysis on Dune](https://ton.org/en/ton-on-chain-data-analysis-dune)
- [How to Analyze TON Users and Token Flows](https://ton.org/en/how-to-analyze-ton-users-and-token-flows-on-dune)

## Contributing

PRs welcome! If you find a new code_hash, a missing label, or a better SQL pattern — please contribute.

## Contact

[x.com/danokhlopkov](https://x.com/danokhlopkov) | [t.me/danokhlopkov](https://t.me/danokhlopkov)

## License

MIT
