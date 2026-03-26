# DEX Wash Trading / Arb Bot Detection

How to identify and quantify CEX-DEX arbitrage activity that inflates reported DEX volume.

## What It Is

CEX-DEX arbitrage bots exploit price differences between centralized exchanges and on-chain DEXes. They are NOT pure wash trading (there's a real profit motive), but they inflate reported organic volume by 40-48%.

## Detection Methodology

### Step 1: Identify Candidate Wallets

```
Signals of arb bot wallets:
- Contract type: wallet_highload_v3r1 (designed for high-frequency operations)
- Shared funding source (multiple wallets funded from same parent)
- High round-trip ratio: >80% of buys are followed by sells (or vice versa) within same hour
```

### Step 2: Same-Hour Buy+Sell Pattern

The strongest signal. For each wallet, check if it both buys and sells the same token within the same hour on DEX. A legitimate trader occasionally does this; an arb bot does it consistently (hundreds of matched hours).

Query approach:
1. Join `ton.dex_trades` with `result_cex_flows_daily` to find wallets active on both
2. Group by wallet + hour, check for both buy and sell in same hour
3. Filter for wallets with >80% of their hours showing matched trading

### Step 3: Cluster Identification

Arb bots typically operate as clusters (3-6 wallets, shared funder). Use first-funder analysis from [flow-tracing.md](flow-tracing.md) to group wallets.

### Step 4: Per-DEX Impact

Arb share varies significantly by DEX. Measure per-DEX to understand which pools are most affected.

## Pitfalls

- **Arb ≠ wash trading.** Arb bots provide real price discovery. Don't call it "fake volume" — call it "non-organic" or "arb volume."
- **One CEX dominates.** Most arb flow routes through a single exchange. Don't assume even distribution.
- **Growing trend.** Arb share has increased over time (from ~39% to ~48% over 3 months). Always report the time period.
- **Net impact is negligible.** Despite large gross volume, arb bots are roughly net-zero on buy/sell pressure.

## Organic Volume Calculation

```
Organic DEX volume = Total DEX volume - Arb bot volume
```

Report both numbers. The organic number is what matters for ecosystem health metrics.

## Related

- [cex-flows.md](cex-flows.md) — CEX side of arb flows
- [flow-tracing.md](flow-tracing.md) — cluster identification via funding analysis
- [../dune/dashboards.md](../dune/dashboards.md) — DEX-related dashboards
