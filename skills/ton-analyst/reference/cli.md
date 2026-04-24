# `ton` CLI — reference

A single-file Python CLI (`skills/ton-analyst/bin/ton`) that wraps the TONAPI
endpoints, address format conversion, the local `ton-labels` repo, and the
enrichment API into terse one-line-per-record output. Designed to replace the
`curl | python3 -c "..."` pattern that dominates every labeling research.

## Install

The skill's `setup` script creates `~/.local/bin/ton -> skills/ton-analyst/bin/ton`.

Manual:

```bash
chmod +x skills/ton-analyst/bin/ton
ln -sf "$PWD/skills/ton-analyst/bin/ton" ~/.local/bin/ton
```

Dependencies (already installed in a typical environment):

- Python 3.9+ (stdlib only beyond these two)
- `requests`
- `pytoniq_core` (address format conversion)

## Environment

| Var | Required | Default | Notes |
|-----|----------|---------|-------|
| `TONAPI_KEY` | no | — | Recommended — bumps rate limits on `tonapi.io` (10 rps → higher). |
| `TON_PROFILER_API_TOKEN` | yes for `profile` | — | Enrichment API token. Without it, `ton profile` errors out and `ton label` skips the profile fallback. |
| `TON_PROFILER_API_URL` | no | `https://profiler.swanrate.com` | Override only if using a non-default endpoint. |
| `TON_LABELS_CACHE` | no | `~/.cache/ton-labels` | Path to a local cache clone of `github.com/ton-studio/ton-labels`. The CLI auto-clones it on first use, rebuilds a flat `_index.json` of all addresses, and refreshes weekly (or with `ton label --refresh`). If git isn't available, the local step silently falls back to empty. |

## Design principles

- **Terse by default.** One line per record, tab-separated, designed for
  `awk`/`grep`/`cut`. No multi-line JSON dumped into the agent's transcript.
- **`--json` escape hatch.** Every subcommand supports it when the raw shape is
  needed.
- **Addresses in, friendly addresses out.** Accepts raw / `UQ` / `EQ` / `-1:`
  inputs; emits `UQ` for human columns and full raw UPPERCASE for machine use.
  Never truncates.
- **Context budget.** Every command has a `--limit` (default 20) — no
  runaway output.
- **Fail loud.** Non-zero exit on HTTP errors, with a single-line stderr
  message. No silent `2>/dev/null` masking.

## Subcommands

### `ton addr <input>`

Normalize between address formats.

```
$ ton addr UQArn1Mhw4cBFoijbQc5ZIZ4UHDrbsXFOlbW-bBkY2SAzMIq
raw     0:2B9F5321C387011688A36D07396486785070EB6EC5C53A56D6F9B064636480CC
uq      UQArn1Mhw4cBFoijbQc5ZIZ4UHDrbsXFOlbW-bBkY2SAzMIq
eq      EQArn1Mhw4cBFoijbQc5ZIZ4UHDrbsXFOlbW-bBkY2SAzJ_v
wc      0
```

`--json` yields `{raw, uq, eq, workchain}`.

### `ton acc <addr>`

One-line account summary plus a details block with raw/eq.

```
$ ton acc 0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309
addr=UQDKHZ7e...CSRH  balance=3549982.41 TON  status=active  name=Binance Hot Wallet  interfaces=wallet_highload_v3r1  scam=None  wallet=True
raw     0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309
eq      EQDKHZ7e70CzqdvZCC83Z4WVR8POC_ZB0J1Y4zo88G-zCVvS
```

### `ton tx <addr> [flags]`

Transaction list. Each output row = one message (IN or OUT) that matched the
filters. Columns: `ts  dir  value_ton  counterparty_uq  op  comment`.

| Flag | Effect |
|------|--------|
| `--out` | only outgoing messages |
| `--in` | only incoming messages |
| `--min-value N` | skip messages below N TON |
| `--limit N` | max rows to print (default 20) |
| `--since YYYY-MM-DD` | UTC lower bound — stops paginating once older txs are reached |
| `--dest <addr>` | for OUT messages, keep only those whose destination matches |
| `--json` | raw JSON, one dict per row |

Example — large outflows from a wallet in 2025:

```
$ ton tx 0:2B9F5321... --out --min-value 5 --limit 10
# ts                  dir  value_ton  counterparty                                       op            comment
2025-12-15 19:48:34   OUT  236.6270   UQDgzUt9BY3fQJFPY6HD7xARfb6VwFB9KJRd0KToA_AxoJEo    -             -
2025-12-13 14:21:09   OUT  125.0000   UQDgzUt9BY3fQJFPY6HD7xARfb6VwFB9KJRd0KToA_AxoJEo    -             -
2025-12-12 16:31:25   OUT   10.0000   UQCf0pcgE-R7OOfll8MbxqOxAjBA6q2ZhqQsIMWn0Z62XMUz    text_comment  ee1637
...
```

### `ton dns <target>`

Forward resolve if the input looks like a domain, reverse if it looks like an
address.

```
$ ton dns pavel-capital.ton
domain    pavel-capital.ton
owner     UQArn1Mhw4cBFoijbQc5ZIZ4UHDrbsXFOlbW-bBkY2SAzMIq
owner_raw 0:2B9F5321C387011688A36D07396486785070EB6EC5C53A56D6F9B064636480CC
nft_item  0:02A1E2F33B0C0F80588F6D6016B57B33912D3B6A7F67598A8CC8B9D18A63921C
expires   2026-08-09 17:57:10

$ ton dns 0:CA1D9EDE...
# no reverse DNS records
```

### `ton profile <addr>`

Enrichment lookup (internal API). Prints cluster name, cluster size, tags,
flags, then one line per related address with `uq  alias  relation_types  tags`.

| Flag | Effect |
|------|--------|
| `--related-only` | print only the related addresses' raw uppercase form, one per line — suitable for `xargs`/`while read` pipelines |
| `--limit N` | cap related-addresses output (default 20) |

### `ton label <addr> [--refresh]`

Quick label check. Tries in order and returns the first hit:

1. `tonapi.io /v2/accounts/{addr}.name` (e.g. "Binance Hot Wallet")
2. TONAPI DNS backresolve — first owned `.ton` domain
3. Local ton-labels cache (auto-cloned to `~/.cache/ton-labels`; flat index keyed by raw uppercase address)
4. Profile lookup (requires `TON_PROFILER_API_TOKEN`)

`--refresh` forces a `git pull` of the cache and a full rebuild of the flat index.

Output: `uq_addr  label  category  source`. Exit code 3 if nothing matched.

```
$ ton label 0:CA1D9EDE...
UQDKHZ7e70CzqdvZCC83Z4WVR8POC_ZB0J1Y4zo88G-zCSRH   Binance Hot Wallet   wallet_highload_v3r1   tonapi:name
```

### `ton chain <addr> [--depth N]`

Walks backwards through the earliest inbound sender of each hop. Stops at the
first labeled address or at `--depth` (default 5). One line per hop.

```
$ ton chain 0:2B9F5321... --depth 3
# hop  address_uq                                           label            source
0      UQArn1Mhw4cBFoijbQc5ZIZ4UHDrbsXFOlbW-bBkY2SAzMIq     -                -
1      UQBDanbCeUqI4_v-xrnAN0_I2wRvEIaLg1Qg2ZN5c6Zl1P5k     Wallet Bot 2     tonapi:name
```

Note: TONAPI has no direct "first_tx_sender" field, so the CLI paginates
descending `/transactions` and keeps the oldest inbound sender seen. Hard-capped
at ~1000 transactions per hop.

### `ton jetton <addr>`

Jetton balance list. Columns: `symbol  name  balance  jetton_master_uq`.
Pass `--limit` (default 20) to cap.

## Measured savings

Three demos from today's research (`2026-04-24 Probe Wallet Labeling`),
measured on a live terminal:

| Question | Old pattern | New pattern | Raw JSON bytes | CLI output bytes |
|----------|-------------|-------------|----------------|------------------|
| Is `0:CA1D9EDE...` a known CEX? | `curl .../accounts/{a}` + `python3 -c "d=json.load(sys.stdin); print(d['name'])"` | `ton label 0:CA1D9EDE...` | 164 → `...name=Binance Hot Wallet,interfaces=wallet_highload_v3r1...` | **~100** |
| Top 20 large outflows from `UQArn1...` since 2024 | `curl .../transactions?limit=100` (20-30 KB) + inline Python filter (~800 chars) | `ton tx 0:2B9F5321... --out --min-value 5 --limit 20 --since 2024-01-01` | **386,215** | **1,785** (216× reduction) |
| Deployer chain for `UQDfE7Ws...` | paginate tx history manually + label each hop | `ton chain 0:DF13... --depth 3` | 19 (empty) → no walk needed | 84 |

Aggregate across a typical labeling research (10-15 TONAPI queries + 3-5 label
checks + 1-2 deployer walks): **~10 fewer Bash calls and ~30-40 KB less JSON**
dumped into the agent's context.

## When NOT to use `ton`

- Batch labeling of > 50 addresses → hit `POST /api/v1/addresses/tags` directly;
  the CLI doesn't expose the batch endpoint yet (planned).
- Full event/trace reconstruction (jetton jetton-wallet graphs, DEX swap
  traces) → use TONAPI's `/v2/accounts/{addr}/events` and parse manually.
- Anything requiring Dune SQL — use the Dune MCP tools.

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | generic error (bad flag, HTTP >= 400 not covered below) |
| 2 | missing dependency |
| 3 | `ton label` couldn't find anything |
| 4 | TONAPI 404 (address / DNS not indexed) |
| 5 | TONAPI rate-limited (set `TONAPI_KEY`) |
