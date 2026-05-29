# Comment Pattern Analysis

Analyze transaction comments to classify unknown addresses and understand service behavior.

**Discovery — find addresses with consistent comment patterns:**
```sql
-- Find addresses receiving many transactions with structured comments
SELECT
    M.destination,
    L.name AS label_name,
    COUNT(*) AS total_txs,
    COUNT(DISTINCT M.source) AS unique_senders,
    COUNT(DISTINCT M.comment) AS unique_comments,
    CAST(COUNT(DISTINCT M.comment) AS DOUBLE)
        / NULLIF(COUNT(DISTINCT M.source), 0) AS comment_sender_ratio,
    SUM(M.value) / 1e9 AS total_ton
FROM ton.messages M
LEFT JOIN dune.ton_foundation.dataset_labels L ON L.address = M.destination
WHERE M.direction = 'in' AND NOT M.bounced
    AND M.block_date >= CURRENT_DATE - INTERVAL '90' DAY
    AND M.comment IS NOT NULL AND M.comment != ''
    AND regexp_like(M.comment, '^[0-9]{4,13}$')  -- numeric IDs
GROUP BY 1, 2
HAVING COUNT(*) >= 100 AND COUNT(DISTINCT M.source) >= 50
ORDER BY total_txs DESC
LIMIT 50
```

**Interpreting comment_sender_ratio:**
- `~1.0` = each sender uses one consistent comment (deposit memos, user IDs)
- `>>1` = same sender sends many different comments (batch payments, subscriptions)
- `<<1` = many senders share the same comment (unlikely for unique IDs)

**Cross-validating comment semantics across addresses:**
When two addresses receive numeric comments from overlapping wallets, check if the same wallet sends the same comment to both. High match rate means the comments carry the same semantic (e.g., both use deposit account IDs). Zero match rate despite wallet overlap means the comments are unrelated (different ID systems).

```sql
-- Cross-validate: do wallets send the same comment to address A and B?
WITH pairs_a AS (
    SELECT DISTINCT source, comment FROM ton.messages
    WHERE destination = '0:ADDRESS_A' AND direction = 'in'
      AND regexp_like(comment, '^[0-9]{4,13}$')
      AND block_date >= DATE '2024-06-01'
),
pairs_b AS (
    SELECT DISTINCT source, comment FROM ton.messages
    WHERE destination = '0:ADDRESS_B' AND direction = 'in'
      AND regexp_like(comment, '^[0-9]{4,13}$')
      AND block_date >= DATE '2024-06-01'
)
SELECT
    COUNT(DISTINCT B.source) AS wallets_in_both,
    COUNT(DISTINCT CASE WHEN A.comment = B.comment THEN B.source END) AS same_comment_match,
    ROUND(CAST(COUNT(DISTINCT CASE WHEN A.comment = B.comment THEN B.source END) AS DOUBLE)
        / NULLIF(COUNT(DISTINCT B.source), 0) * 100, 1) AS match_pct
FROM pairs_b B
LEFT JOIN pairs_a A ON A.source = B.source
```

**Common comment formats on TON:**
| Pattern | Example | Typical use |
|---------|---------|-------------|
| `^[0-9]{4,13}$` | `1234567890` | User IDs, deposit memos |
| `^Ref#[0-9]+$` | `Ref#48291` | Fragment payments |
| `^[A-Za-z]+-[0-9]+$` | `app-12345` | App-prefixed IDs |
| `^[^:]+:[0-9]+$` | `deposit:99887` | Colon-separated IDs |
| `^\{.*\}$` | `{"user_id":123}` | JSON payloads |
| `^[0-9]{10}[0-9]{4,13}$` | `17112345001234567` | Timestamp + ID concatenated |
