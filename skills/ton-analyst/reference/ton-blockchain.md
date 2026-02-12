# TON Blockchain Concepts

Essential knowledge for analysts working with TON on-chain data.

## Address Architecture

**Key fact:** In TON, every address is a smart contract. No "EOA" (externally owned accounts) like Ethereum.

- **Wallet contracts** — user wallets (wallet_v3r2, wallet_v4r2, wallet_v5r1, multisig)
- **Custom contracts** — DEX, lending, games, bridges, any logic
- **uninit addresses** — created (have balance) but never activated (no code deployed)

Filter "real users" via `ton.accounts.interfaces` — wallet or multisig interface + anti-join on labels.

## Address Formats & Conversion

| Format | Example | Used In |
|--------|---------|---------|
| Raw | `0:b113a994b5024a16719f69139328eb759596c38a25f59028b146fecdc3621dfe` | Dune (always UPPERCASE) |
| Non-bounceable (UQ) | `UQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_lqN` | Wallets, display |
| Bounceable (EQ) | `EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_rS4` | Smart contracts |

**On Dune:**
```sql
-- Raw → User-friendly
ton_address_raw_to_user_friendly(raw_address)
-- User-friendly → Raw
ton_address_user_friendly_to_raw(friendly_address)
```

**Locally (Python):**
```python
from pytoniq_core import Address
addr = Address("UQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_lqN")
raw = addr.to_str(is_user_friendly=False)  # 0:b113a994...
```

Always verify with roundtrip test: `raw → friendly → raw` must match original.

## Staking

**Elector balance = Total TON staked (native staking)**

- Address: `-1:3333333333333333333333333333333333333333333333333333333333333333`
- Masterchain contract where validators and nominators deposit TON
- Nominators use pools (lower threshold than validators)
- Track via `dune.ton_foundation.result_nominators_cashflow`

**Liquid staking** (tsTON, stTON) is separate — not in the Elector. Track via `result_external_balances_history`.

## CEX Infrastructure

CEX = Exchange main wallets + Custodial deposit wallets.

1. **Main wallets** — `dataset_labels` where `category = 'CEX'` (~643 addresses, ~127M TON)
2. **Deposit wallets** — `result_custodial_wallets` (~9.6M addresses, ~35M TON)

Always combine both into one "CEX" group for analytics.

## Traces vs Transactions vs Messages

TON execution model differs from EVM:

- **Message** — a single transfer between two contracts
- **Transaction** — one contract processing one incoming message (may produce outgoing messages)
- **Trace** — the full execution tree from initial external message through all internal messages

`trace_id` = hash of the first transaction in the trace. Use it to group related operations.

## DeFi Categories

| Category | Examples |
|----------|---------|
| dex | DeDust, Ston.fi |
| lending | EVAA, Affluent |
| bridge | bridge.ton.org, LayerZero |
| liquid-staking | Tonstakers, Bemo, Hipo |
| defi (other) | Fiva, Torch |

For analytics: combine all into "DeFi" group.

## Data Quality

**Token price manipulation:** People create small LP pools with inflated supply — artificial price. Balance x price = trillions. Fix: whitelist tokens by TVL > $10K.

**Spam tokens:** Filter known spam (e.g., `0:87DAC05A...`) at analysis stage.

**pTON:** `0:1150B518...` is StonFi wrapped TON intermediary. Exclude from graphs if swap edge exists.
