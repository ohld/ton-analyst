# `ton` CLI reference

A minimal Python CLI wrapping the TONAPI REST API with aggressive field pruning. Goal: let an AI agent ask simple on-chain questions without burning context on raw JSON.

**MVP: two subcommands.** Everything else is in [`bin/TODO.md`](../bin/TODO.md) as a backlog of ideas.

## Install

From repo root: `./skills/ton-analyst/setup`. Creates a venv at `skills/ton-analyst/.venv`, installs `httpx` + `pytoniq-core`, drops a wrapper at `~/.local/bin/ton`. Uninstall: `./skills/ton-analyst/setup --uninstall`.

The repo root already ships its own `setup` script that symlinks the skill into `~/.claude/skills/`; the CLI installer is separate and lives inside the skill dir so it can be shipped/moved with it.

Python 3.10+ required.

## Environment

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `TONAPI_API_KEY` | no | — | Bearer token for higher TONAPI rate limits. `TONAPI_KEY` also accepted. |
| `TONAPI_BASE` | no | `https://tonapi.io` | Override API base URL. |
| `TON_LABELS_CACHE` | no | `~/.cache/ton-labels` | Where the built `ton-labels` CSV is cached (`assets.csv` + `assets.csv.etag` + `_index.json`). Fetched from the `ton-studio/ton-labels` `build` branch on first `ton acc` call; revalidated after 24h via ETag conditional GET. |

## `ton acc <addr>`

One-line account summary. Accepts any address format (raw `0:...`, UQ, EQ).

```
ton acc 0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309
# →
# 0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309	Binance Hot Wallet	active	3511508.124	-	@BTC25:2.1e+13;SHUFIK:9e+12;Lcoin:1.8e+11;$PZDC:1e+11;$X:9e+10
```

Columns: `address \t label \t status \t balance_ton \t flags \t top_jettons`.

- **label**: local `ton-labels` hit (format `label/category`) → TONAPI `name` → `-`.
- **flags**: comma-separated: `scam`, `memo`, `contract` (or `-`).
- **top_jettons**: semicolon-separated `SYMBOL:amount` pairs, top-N by balance (N = `--jettons`, default 5, 0 to disable).

Flags:
- `--jettons N` — top-N jettons to show (default 5, 0 to skip jetton endpoint).
- `--json` — emit the pruned raw account object (drops `interfaces`, `get_methods`, `icon`).

## `ton tx <addr>`

Transaction history, one row per transfer leg. Default TSV, `--json` for pruned nested TONAPI shape.

```
ton tx 0:2B9F5321C387011688A36D07396486785070EB6EC5C53A56D6F9B064636480CC --out --min-value 5 --limit 5
# →
# 2025-12-15 19:48:34	64689256000001	OUT	0:e0cd4b7d...	236.627	-
# 2025-12-13 14:21:09	64611570000001	OUT	0:e0cd4b7d...	125	-
# 2025-12-13 14:10:42	64611317000001	OUT	0:e0cd4b7d...	15	-
# 2025-12-12 16:31:25	64579736000001	OUT	0:9fd29720...	10	ee1637
# 2025-12-12 15:35:58	64578399000001	OUT	0:8cc10cb7...	10	c908bf
# (stderr) # next page: --before-lt 64578399000001
```

Columns: `ts \t lt \t direction \t counterparty \t value_ton \t comment`.

The pagination cursor is always printed to **stderr** so it never pollutes a piped stdout.

Flags:

| Flag | Purpose |
|---|---|
| `--in` | incoming only |
| `--out` | outgoing only |
| `--min-value TON` | drop transfers below this TON amount |
| `--since YYYY-MM-DD` | earliest UTC date to include (exits once history goes older) |
| `--before YYYY-MM-DD` | latest UTC date to include |
| `--dest ADDR` | filter by counterparty address |
| `--limit N` | max rows to print (default 20) |
| `--before-lt LT` | pagination cursor (see stderr footer of previous call) |
| `--json` | pruned nested TONAPI tx objects, one per line |

In `--json` mode, per-tx pruning drops: `compute_phase`, `storage_phase`, `credit_phase`, `action_phase`, `bounce_phase`, `aborted`, `destroyed`, `orig_status`, `end_status`, `total_fees`, `state_update`, `block`, `prev_trans_*`, `raw`. Per-message pruning drops: `init`, `raw_body`, `message_content`, `decoded_op_name`, `import_fee`, `ihr_fee`, `fwd_fee`, `ihr_disabled`, `ihr_pending`, `fwd_pending`, `bounce`, `bounced`, `created_lt`, `created_at`, `hash`. Additionally, `source` and `destination` sub-objects are reduced to just `{"address": "..."}` (the other fields — `is_scam`, `is_wallet`, `icon`, `name` — are mostly redundant with `ton acc` lookups). Decoded comment (if present) is surfaced as a flat `comment` field.

## Pagination workflow

```bash
# First page:
ton tx $ADDR --out --limit 100
# Look at stderr footer: "# next page: --before-lt 46893163000001"

# Next page:
ton tx $ADDR --out --limit 100 --before-lt 46893163000001
```

## Exit codes

| Code | Meaning |
|---|---|
| 0 | ok (empty history is still 0; `ton tx` prints nothing and exits normally) |
| 2 | usage / bad address |
| 3 | address not found (TONAPI returned 404) |
| 4 | network or HTTP error |

## Not in MVP

See [`bin/TODO.md`](../bin/TODO.md). Notable deferrals: `ton dns`, `ton chain` (inviter walk), `ton jettons` (full list), batch lookups, NFT history.
