# DEX Arbitrage Analysis

CEX-DEX arbitrage bots exploit price differences between centralized exchanges and on-chain DEXes. They provide real price discovery (not wash trading), but represent 40-48% of TON/USDT DEX volume. Understanding their share helps interpret ecosystem metrics correctly.

## Detection Signals

- **Same-hour round-trip:** wallet buys and sells the same token on DEX within the same hour, consistently (hundreds of matched hours). This is the strongest signal — join `ton.dex_trades` with `result_cex_flows_daily` to find wallets active on both, group by wallet+hour.
- **Shared funding source:** multiple wallets funded from same parent → likely same operator. Use first-funder analysis from [flow-tracing.md](flow-tracing.md).
- **High-throughput wallet types:** `wallet_highload_v3r1` is common among arb bots (designed for many transactions), but not exclusive to them.

## Key Insight

Arb bots are roughly **net-zero** on buy/sell pressure despite large gross volume. They are legitimate DEX users — don't subtract them to get "real" volume, but do report their share for context. Per-DEX arb share varies significantly.

**Dashboard:** [TON Verticals](https://dune.com/ton_foundation/verticals) — includes DEX volume breakdown.
