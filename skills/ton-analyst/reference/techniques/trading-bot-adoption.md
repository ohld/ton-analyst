# Trading Bot Adoption

Use this pattern to estimate Telegram trading-bot activity on TON when the bot
charges a visible TON fee to a known collector wallet.

Reference dashboard: [Trading Bots on TON](https://dune.com/xrocket_tg/trading-bots-on-ton)
by `xrocket_tg`. Dashboard queries: [Q5350885](https://dune.com/queries/5350885),
[Q5351146](https://dune.com/queries/5351146).

Runnable examples:

- [trading-bot-fee-adoption.sql](../dune/examples/trading-bot-fee-adoption.sql)
- [trading-bot-query-id-dex-volume.sql](../dune/examples/trading-bot-query-id-dex-volume.sql)

Source bot queries: [DTrade Q5351226](https://dune.com/queries/5351226),
[tontrade Q5351266](https://dune.com/queries/5351266), [Blum Q5351280](https://dune.com/queries/5351280),
[Grim Q5351284](https://dune.com/queries/5351284), [Sky Q5351288](https://dune.com/queries/5351288),
[PocketFi Q5352425](https://dune.com/queries/5352425), [Stonks Q5436727](https://dune.com/queries/5436727),
[Maestro Q5436754](https://dune.com/queries/5436754), [x1000 Q5854229](https://dune.com/queries/5854229),
[Swapi Q6191943](https://dune.com/queries/6191943), [Groyp Q7453230](https://dune.com/queries/7453230),
[redo Q7586087](https://dune.com/queries/7586087), [not.trade Q7598895](https://dune.com/queries/7598895).

## Core Heuristic

Most source queries use `ton.messages` inbound transfers:

- `direction = 'in'` and `NOT bounced`
- `destination` is a known bot fee receiver
- `comment` matches a bot-specific memo when available
- `fee_ton = SUM(value) / 1e9`
- `inferred_volume_ton = fee_ton / fee_rate`
- `daily_transactions = COUNT(*)`
- `daily_unique_traders = COUNT(DISTINCT source)`

The xRocket dashboard mostly assumes `fee_rate = 1%`, so it uses
`SUM(value * 100) / 1e9` for volume. Treat that as inferred trading volume, not
direct DEX volume.

## Caveats

- This measures fee payments, not swaps. It is reliable for fees and adoption,
  but volume depends on knowing the bot fee rate.
- `source` is the fee payer, which may be a bot-controlled intermediate wallet,
  not always the human user's wallet.
- Memo filters are weak by themselves. Prefer `destination + memo`, and require
  address-only rules to be backed by label or product knowledge.
- Not all source queries use the same lookback. Some are named "last 6 months"
  but only scan 1 month.
- Use complete-day windows (`block_time < CURRENT_DATE`) for dashboards, or
  explicitly include today with `block_time < CURRENT_DATE + INTERVAL '1' DAY`.
  `block_time <= CURRENT_DATE` excludes most of the current UTC day.
- Always add a `block_date` partition filter alongside `block_time`.

## Stronger Trade Linking

When a bot embeds a stable `query_id` namespace in swap messages, prefer
`ton.dex_trades` for volume and use fee messages only for fee revenue. The
`x1000` source query uses:

```sql
BITWISE_RIGHT_SHIFT(COALESCE(dt.query_id, je.query_id), 32) = 988547769
```

with `ton.jetton_events` as a fallback source of `query_id` by `trace_id`. This
is stronger than `fee / fee_rate` because `volume_ton`, `volume_usd`, trade
count, and trader count come from decoded DEX trades.

## Useful Next Checks

1. Compare fee-inferred volume against `ton.dex_trades` volume where a bot has
   `query_id`, `platform_tag`, referral, or router-level markers.
2. Split repeat users from one-off users with retention cohorts on `source`.
3. Join fee payer addresses to labels, sybil sets, and first funders before
   treating `daily_unique_traders` as real users.
4. Watch fee-rate changes over time. A fixed multiplier can silently break.
