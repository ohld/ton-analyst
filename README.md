# ton-analyst

Claude Code skill for TON blockchain data analysis on [Dune Analytics](https://dune.com).

## What it does

- Generates Dune SQL queries for TON on-chain analysis
- Executes queries via Dune API and analyzes results
- Covers supply distribution, wallet analysis, token flows, DeFi activity, staking, CEX flows, DEX bots/MEV
- Includes battle-tested SQL patterns for 13-category supply classification, real user filtering, whale tiers

## Install

In Claude Code, run:

```
/plugin marketplace add ohld/ton-analyst
/plugin install ton-analyst@ton-analyst
```

This adds the repo as a marketplace source and installs the skill.

Codex/local install: `./setup --host codex`. Other local hosts: `./setup --host agents` or `./setup --host claude`.

## Updates

ton-analyst uses explicit versions. When the skill is invoked, it checks the published `VERSION` file and tells you if a newer release is available. Full flow: [`skills/ton-analyst/reference/update-flow.md`](skills/ton-analyst/reference/update-flow.md).

To update manually in Claude Code:

```
/plugin marketplace update ton-analyst
/plugin update ton-analyst@ton-analyst
/reload-plugins
```

Claude Code can also auto-update marketplaces at startup when auto-update is enabled for the marketplace in `/plugin` → Marketplaces.

For Codex/local git installs, pull the repo (`git -C /path/to/ton-analyst pull --ff-only`) and relaunch the agent.

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
├── SKILL.md                    # Entry point — update check, routing, core rules
├── VERSION                     # Runtime version used by the update checker
├── bin/
│   ├── ton                     # TONAPI CLI wrapper
│   ├── ton-analyst-update-check
│   └── TODO.md                 # deferred subcommand ideas
├── setup                       # venv + wrapper installer
├── pyproject.toml              # CLI dependencies and pytest config
├── uv.lock
├── tests/                      # pytest suite, httpx.MockTransport — no network
└── reference/
    ├── cli.md                  # `ton` CLI reference
    ├── update-flow.md          # Versioning and local/marketplace update flow
    ├── dune/                   # MCP/API workflow, schemas, query patterns, examples
    ├── ton/                    # TON model, TONAPI, labels, address investigation
    └── techniques/             # CEX flows, staking, vesting, MEV, MAU, fees
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
2. Install locally: `./setup --host codex`, `./setup --host agents`, or `./setup --host claude`
3. Edit files in `skills/ton-analyst/`
4. Run tests: `cd skills/ton-analyst && uv run pytest`
5. Submit a PR with your changes

### What to contribute

- New SQL examples — add `.sql` files in `reference/dune/examples/`
- New table schemas or gotchas — edit `reference/dune/schemas/` or `reference/dune/query-patterns.md`
- New labels or address discoveries — edit `reference/ton/labels.md`
- Bug fixes in existing SQL — edit the relevant file

## Resources

- [Dune TON Tables Overview](https://docs.dune.com/data-catalog/ton/overview)
- [TON Documentation](https://docs.ton.org/)
- [TON Verticals Dashboard](https://dune.com/ton_foundation/verticals)
- [TON DEX traders smart-contract evolution](https://dune.com/pshuvalov/ton-traders-types-analysis)
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
