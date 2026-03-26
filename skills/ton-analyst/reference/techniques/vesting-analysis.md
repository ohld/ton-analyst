# Vesting & Locker Analysis

TON has significant locked supply in two main vesting mechanisms: TON Believers Fund and Telegram vesting contracts.

## TON Believers Fund (TBF)

- **Contract source:** [ton-blockchain/locker-contract](https://github.com/ton-blockchain/locker-contract)
- **Lock:** 2 years (Oct 2023 → Oct 2025), then 36 monthly vesting payments
- **APY:** ~7% (deposited via tx comment `"r"` by external wallets, not from staking)
- **Dashboard:** [TON Believers Fund](https://dune.com/ton_foundation/ton-believers-fund)

Transaction comments: `"d"` = deposit, `"w"` = withdraw, `"r"` = reward. Filter in `ton.messages`.

### Sell Pressure Estimation

```
Theoretical max = Monthly unlock amount
Actual sell pressure = Claimed amount × CEX deposit rate
```

Not all unlocked TON gets claimed — measure claim rate (historically ~12%). Use 4-hop ratio attribution ([flow-tracing.md](flow-tracing.md)) to trace destinations. Wallets with balance < 10% of received are forwarders — trace one more hop.

## Telegram Vesting Contracts

- **Contract source:** [ton-blockchain/vesting-contract](https://github.com/ton-blockchain/vesting-contract)
- **Parameters:** 1440-day duration, 360-day cliff
- **Detection:** Identify via `code_hash` in `ton.accounts` (see [query-patterns.md](../dune/query-patterns.md) code hash reference)
- **Deployer identification:** Find the address that deployed these contracts by checking the first inbound message to each vesting contract. Multiple deployers exist — Telegram uses specific deployer addresses.

**Caveat:** The vesting contract is open-source. Other entities also deploy it with different parameters — don't assume all vesting contracts are Telegram's. Verify the deployer.

## Liquid Staking Gotcha

BF recipients sometimes send to liquid staking. Deposits go to **pool contracts**, not jetton masters — see [staking-analysis.md](staking-analysis.md).
