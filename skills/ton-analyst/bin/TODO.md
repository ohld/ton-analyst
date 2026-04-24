# `ton` CLI — future subcommands (not in MVP)

MVP ships only `ton acc` and `ton tx`. These are candidates for follow-up PRs — each should wait until there's real demand from an agent's research session, not speculative utility.

- **`ton dns <domain-or-addr>`** — forward (`foo.ton` → address) and reverse (address → owned domains) DNS resolve. Hits `/v2/dns/{domain}` and `/v2/accounts/{addr}/dns/backresolve`.
- **`ton addr <input>`** — print all address formats (raw, UQ, EQ, workchain) for an input. Trivially inline today, but handy when scripting.
- **`ton chain <addr> [--depth N]`** — walk the funding/deploy chain upward until hitting a labeled address. TONAPI doesn't expose `first_tx_sender` directly; would need careful heuristic over the oldest inbound transaction page. Stop at first labeled hop.
- **`ton jettons <addr>`** — full jetton balance listing (not just top-N embedded in `acc`).
- **`ton acc --batch`** and **`ton label --batch`** — read a list of addresses from stdin and emit one row per line. Kills the "check 50 addresses" Dune query pattern.
- **`ton nft <addr>`** — NFT holdings summary.
- **`ton cache warm`** — pre-seed the ton-labels cache during `./setup` so the first `ton acc` on an unlabeled wallet isn't slowed by a ~15s shallow-clone.

When implementing any of these, keep the MVP's invariants: terse TSV default, `--json` escape hatch, aggressive field pruning, no bytecode / code_hash / icon URLs in the output.
