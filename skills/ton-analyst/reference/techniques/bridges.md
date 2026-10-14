# Bridge Analytics

How TON bridge volume and users are counted on the public dashboard, how to add
a bridge, and how to handle escrow/HTLC bridges that use a cross-chain resolver.

## Canonical Sources

- Dashboard: [dune.com/ton_foundation/bridges](https://dune.com/ton_foundation/bridges)
- All 6 charts come from one query: [Q5829472](https://dune.com/queries/5829472) ("TON Blockchain Bridges Stats")
- Bridge addresses come **only** from [ton-labels](https://github.com/ton-studio/ton-labels)
  `assets/bridge/*.json`, exposed on Dune as `dune.ton_foundation.dataset_labels`
  (`category = 'bridge'`)

The single place to add or fix a bridge is a ton-labels PR. After merge, the
Dune upload workflow refreshes `dataset_labels` and the dashboard picks it up
with no SQL edits. Do not hardcode bridge addresses in queries.

## Adding a New Bridge

1. Find the bridge's custody / escrow / vault addresses. Confirm on
   tonviewer/tonapi that real user deposits and payouts touch them.
2. Add them to `assets/bridge/<org>.json` with `organization`, `name`,
   `category: bridge`, and a `source` explaining provenance
   (see [../ton/label-submission.md](../ton/label-submission.md)).
3. Do not label wallets that also run unrelated flows (e.g. merchant/payment
   processors) as bridges: every transfer through them would count as bridged.
4. Verify after merge:

```sql
SELECT organization, count(*) FROM dune.ton_foundation.dataset_labels
WHERE category = 'bridge' GROUP BY 1
```

## Generic Counting Logic

A transfer counts as bridged when:

- it is TON >= 1 TON, or a jetton with a daily USD price;
- **exactly one** side is a bridge address (transfers inside the same bridge are excluded);
- after per `(trace, user, token)` netting, which removes reverted/refunded transfers.

A trace touching two bridges is attributed deterministically to the bridge with
the larger leg. Volume is USD at the daily price.

## Escrow / HTLC Bridges with a Resolver

Example: Omniston (STON.fi cross-chain protocol), resolver "Arbiter".

Naive counting is wrong here: on-chain, the escrow's counterparty is the
**resolver**, not the trader, and refunds look like volume.

Convention: tag the organization's resolver wallet(s) in ton-labels with tags
`resolver` and `cross-chain-resolver`. The query then switches that
organization to order-based counting:

- Each order gets its own per-order escrow contract, created by the escrow
  minter in the deposit trace.
- Resolver-funded order paid out to a user -> bridged **TO** TON (user = recipient).
- User-funded order paid out to the resolver -> bridged **FROM** TON (user = depositor).
- Resolver-funded order paid back to the resolver -> refund, excluded.

Linkage is generic (labels + message structure); no protocol opcodes. A new
resolver-based bridge only needs the two tags, not query changes.

## Active Users

Active users = distinct addresses with a wallet interface (`ton.accounts.interfaces`
like `wallet_*`), i.e. real user wallets, not intermediate contracts. See
[../dune/patterns/labels-real-users.md](../dune/patterns/labels-real-users.md).

## Caveats

1. **Distinct wallets != distinct people.** One actor can split flow across many
   wallets. Example: Omniston to-TON volume in Sep 2026 was ~98% from ~108 wallets,
   each receiving ~$1K orders, one of which consolidated funds from 16 others.
2. **Check concentration before quoting user counts:** top-N share of volume and
   order-size pattern (uniform sizes suggest one operator).
3. Volume is USD at daily price, not execution price.

## Related

- Bridge as a flow-tracing destination: [flow-tracing.md](flow-tracing.md)
- Wallet clustering: [../ton/wallet-investigation.md](../ton/wallet-investigation.md)
