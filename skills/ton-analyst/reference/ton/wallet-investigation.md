# Wallet Investigation Workflow

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

### Step 6: Use the `ton` CLI Before Raw TONAPI

For one concrete address/account/transaction, start with the local `ton` CLI. It wraps TONAPI with field pruning and current labels/events:

```bash
ton acc 0:ADDRESS
ton tx 0:ADDRESS --limit 50
ton tx 0:ADDRESS --out --min-value 5 --limit 20
```

Use Dune for bulk, multi-address, historical, or time-series work. Use direct TONAPI only when `ton acc` / `ton tx --json` cannot expose the field needed for contract analysis.

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
