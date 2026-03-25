# ton-labels: Labelling Guide

How to investigate unlabelled addresses and submit labels to [ton-studio/ton-labels](https://github.com/ton-studio/ton-labels).

## What We Label

- Companies, exchanges, apps, games, DeFi protocols, bridges, validators
- Any **entity** that operates on the TON blockchain
- Multiple addresses per entity are fine (hot wallet, withdrawal wallet, contracts, etc.)

## What We DON'T Label

- Personal wallets of individual people (even if they move large amounts)
- Addresses where we can't identify the operating entity
- Addresses with only circumstantial evidence and no confirmed entity link

## Address Format

All addresses in JSON files must be **user-friendly bounceable** format (starts with `EQ` or `Ef`).

Convert from raw:
```python
from pytoniq_core import Address
addr = Address("0:99C05569ACD04E9677F0E38BFEA4081AE605B1BC7D42B17BDFF12DC291227A30")
print(addr.to_str(True, is_bounceable=True))  # EQCZwFVp...
```

## Proof Requirements

### Option A: One Direct Proof

The entity **explicitly mentions this address** on their official pages:
- Official website, documentation, or app UI shows the address
- TON DNS name (`.ton` domain) resolves to the address and matches the entity
- TONAPI account `name` field matches the entity
- You opened the mini-app, made a payment, and the transaction destination matches

### Option B: Two Indirect Proofs (minimum)

Combine at least two of these:
- **First funder**: the address was first funded by an already-labelled address of the same entity
- **Large volume flow**: significant funds move between this address and already-labelled addresses
- **Transaction comments**: outgoing/incoming comments reference the entity name, bot name, or service
- **Jetton ownership**: contract owns a jetton wallet whose master is controlled by the entity
- **Deployer link**: contract was deployed by the same wallet that deployed other labelled addresses
- **Cluster analysis**: ton-profiler shows the address in the same cluster as labelled addresses

### What Does NOT Count as Proof

- "This address interacts with Entity X" — many addresses interact with popular services
- "Funded from Binance" — millions of addresses are funded from Binance
- Shared `code_hash` alone — multiple entities use the same contract templates
- Pattern similarity (e.g., "sends dust like a spam bot") without identifying the operator

## JSON File Structure

Each entity gets one JSON file in `assets/{category}/entity_name.json`:

```json
{
    "metadata": {
        "label": "entity_name",
        "name": "Entity Name",
        "category": "gaming",
        "subcategory": "",
        "website": "https://example.com",
        "description": "",
        "organization": "entity_name"
    },
    "addresses": [
        {
            "address": "EQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
            "source": "Proof description with [clickable links](https://tonviewer.com/...).",
            "comment": "What this address does (e.g., 'Withdrawal wallet', 'Bonding curve contract').",
            "tags": [],
            "submittedBy": "your_github_username",
            "submissionTimestamp": "2026-03-23T00:00:01Z"
        }
    ]
}
```

### Fields

- `label` / `organization`: lowercase, underscores only (`snake_case`)
- `category`: must match `categories.json` (CEX, gaming, merchant, bridge, wallet, etc.)
- `subcategory`: optional, must match `allowed_subcategories` in `models.py` (e.g., `gambling` for gaming)
- `website`: must start with `https://`, no trailing slash, no query params. Empty string allowed
- `source`: **put your proof here** — include clickable tonviewer links to transactions and addresses
- `tags`: from `tags.json` (e.g., `withdrawal`, `deposit`, `has-custodial-wallets`, `telegram-stars`)

### Validation

Always run before submitting:
```bash
cd ton-labels && python3 build_assets.py
```

This validates: address format, category/tag enums, label uniqueness, no duplicate addresses.

## Investigation Workflow

### Step 1: Find Unlabelled High-Activity Addresses

```sql
-- Unlabelled addresses with highest volume in the past week
WITH LABELS AS (
    SELECT address FROM dune.ton_foundation.dataset_labels
)
SELECT M.source, SUM(M.value / 1e9) AS ton_sent, COUNT(*) AS txs,
       COUNT(DISTINCT M.destination) AS unique_dests
FROM ton.messages M
LEFT JOIN LABELS L ON L.address = M.source
WHERE M.direction = 'in' AND NOT M.bounced
  AND M.block_date >= CURRENT_DATE - INTERVAL '7' DAY
  AND L.address IS NULL
  AND M.value > 1e9  -- >1 TON
GROUP BY 1
ORDER BY 2 DESC
LIMIT 100
```

### Step 2: Identify Who Funded the Address

```sql
-- First funder and largest funder of a target address
SELECT
    A.first_tx_sender,
    COALESCE(L1.organization, A.first_tx_sender) AS first_funder_label
FROM ton.accounts A
LEFT JOIN dune.ton_foundation.dataset_labels L1
    ON L1.address = A.first_tx_sender
WHERE A.address = '0:TARGET_ADDRESS_HERE'
```

```sql
-- Top senders by volume to the target
SELECT M.source,
    COALESCE(L.organization, M.source) AS sender_label,
    SUM(M.value / 1e9) AS ton_sent,
    COUNT(*) AS tx_count
FROM ton.messages M
LEFT JOIN dune.ton_foundation.dataset_labels L ON L.address = M.source
WHERE M.destination = '0:TARGET_ADDRESS_HERE'
  AND M.direction = 'in' AND NOT M.bounced
  AND M.block_date >= DATE '2025-01-01'
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20
```

### Step 3: Analyze Transaction Patterns

```sql
-- Comment patterns (what does the address receive/send?)
SELECT
    CASE
        WHEN comment LIKE '%Telegram Stars%' THEN 'Stars'
        WHEN comment LIKE '%Reward from Telegram%' THEN 'Stars Reward'
        WHEN comment LIKE '%Ref#%' THEN 'Fragment payment'
        WHEN comment IS NULL THEN '[no comment]'
        WHEN LENGTH(comment) < 50 THEN comment
        ELSE SUBSTR(comment, 1, 50) || '...'
    END AS comment_pattern,
    COUNT(*) AS txs,
    SUM(value / 1e9) AS ton_total
FROM ton.messages
WHERE source = '0:TARGET_ADDRESS_HERE'
  AND direction = 'in'
  AND block_date >= CURRENT_DATE - INTERVAL '7' DAY
GROUP BY 1
ORDER BY 3 DESC
LIMIT 20
```

### Step 4: Cross-Reference with Existing Labels

```sql
-- What labelled entities does this address interact with?
SELECT
    L.organization, L.category,
    SUM(CASE WHEN M.source = '0:TARGET' THEN M.value/1e9 ELSE 0 END) AS ton_sent_to_target,
    SUM(CASE WHEN M.destination = '0:TARGET' THEN M.value/1e9 ELSE 0 END) AS ton_sent_from_target
FROM ton.messages M
INNER JOIN dune.ton_foundation.dataset_labels L
    ON L.address = CASE WHEN M.source = '0:TARGET' THEN M.destination ELSE M.source END
WHERE (M.source = '0:TARGET' OR M.destination = '0:TARGET')
  AND M.direction = 'in' AND NOT M.bounced
  AND M.block_date >= CURRENT_DATE - INTERVAL '30' DAY
GROUP BY 1, 2
ORDER BY 3 + 4 DESC
LIMIT 20
```

### Step 5: Check "Inviter of Inviter" Chain

For addresses that fund many new wallets, trace up the chain:
```sql
-- Who invited the inviter?
SELECT
    A.address,
    A.first_tx_sender AS inviter,
    COALESCE(L1.organization, A.first_tx_sender) AS inviter_label,
    B.first_tx_sender AS inviters_inviter,
    COALESCE(L2.organization, B.first_tx_sender) AS inviters_inviter_label
FROM ton.accounts A
LEFT JOIN ton.accounts B ON B.address = A.first_tx_sender
LEFT JOIN dune.ton_foundation.dataset_labels L1 ON L1.address = A.first_tx_sender
LEFT JOIN dune.ton_foundation.dataset_labels L2 ON L2.address = B.first_tx_sender
WHERE A.address = '0:TARGET_ADDRESS_HERE'
```

### Step 6: Use TONAPI for Contract Analysis

```bash
# Account info (name, interfaces, balance)
curl -s "https://tonapi.io/v2/accounts/0:ADDRESS"

# Recent transactions (counterparties, opcodes, comments)
curl -s "https://tonapi.io/v2/blockchain/accounts/0:ADDRESS/transactions?limit=20"

# Jetton balances (what tokens does it hold?)
curl -s "https://tonapi.io/v2/accounts/0:ADDRESS/jettons"

# For jetton masters: get admin address
curl -s "https://tonapi.io/v2/jettons/0:JETTON_MASTER_ADDRESS"
```

## Submitting a PR

1. Fork or branch from `ton-studio/ton-labels`
2. Add/update JSON files in `assets/{category}/`
3. Run `python3 build_assets.py` — must pass
4. Create PR with:
   - **Summary**: which entities, how many addresses
   - **For each address**: clickable proof links (tonviewer transactions, account pages)
   - Use markdown links: `[EQxxxx](https://tonviewer.com/EQxxxx)`

Read the [README](https://github.com/ton-studio/ton-labels/blob/main/README.md) for the full contribution guide.
