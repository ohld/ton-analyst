# Local Learnings

Append repeated analyst mistakes here first. Promote stable rules into the
smallest durable reference file once the fix is clear.

## 2026-05-29

- Core asset constants were too scattered. For TON and canonical USDT, use
  [dune/assets.md](dune/assets.md) before writing balance or jetton-transfer
  queries.
- Do not identify canonical USDT by `symbol = 'USDT'`; many spam jettons reuse
  that symbol. Filter by raw jetton master
  `0:B113A994B5024A16719F69139328EB759596C38A25F59028B146FECDC3621DFE`.
- Heavy Dune detector validation can exceed interactive tool timeouts. Prefer
  saved query creation, explicit execution, then polling results by execution id.
- Executing a source query is not enough to update a `dune.<team>.result_*`
  materialized view table. Use the Materialized Views refresh API, then verify
  the result table itself.
- Broad scammer first-funder expansion creates false positives: victims and spam
  recipients can have large balances. Require behavior from the candidate wallet
  itself, such as repeated outbound dust, before adding it to sybil automation.
