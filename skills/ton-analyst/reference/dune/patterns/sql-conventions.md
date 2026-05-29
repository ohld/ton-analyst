# SQL Conventions and Dune Links

- **Header comment:** Every query starts with `-- created with github.com/ohld/ton-analyst`
- **CTE naming:** UPPER_SNAKE_CASE (`REAL_USERS`, `ALL_LABELS`)
- **WHERE:** `WHERE 1=1` then `AND` for each filter (easy to comment/uncomment)
- **Partition pruning:** Always filter `block_date` early — critical for performance
- **Message filtering:** `direction = 'in' AND NOT bounced`
- **TON conversion:** `/ 1e9` for nanoton to TON
- **Addresses:** Raw UPPERCASE format (full 66-char hex). Never use `UPPER()` — capitalize directly. Friendly (UQ/EQ) only via `ton_address_raw_to_user_friendly()`
- **User wallet display:** `ton_address_raw_to_user_friendly(addr, false)` — non-bounceable UQ for user wallets
- **Clickable links in Dune:** `GET_HREF(url, display_text)` — embed tx links in datetime columns for interactive dashboards
- **Engine:** Presto SQL (Dune) — Trino syntax
- **Array filtering:** `cardinality(FILTER(interfaces, i -> regexp_like(i, '^wallet_.*'))) > 0`

## Dune Hyperlinks (GET_HREF)

Use `GET_HREF(url, display_text)` to make clickable links in Dune table visualizations. Convert base64 hashes to hex for tonviewer URLs: `LOWER(TO_HEX(FROM_BASE64(hash)))`. Works for both `trace_id` and `deployment_tx_hash`.

**Best practice:** embed transaction links inside datetime columns — makes dashboards interactive without adding extra columns.

```sql
-- Transaction link embedded in datetime (preferred — interactive + compact)
GET_HREF(
    'https://tonviewer.com/transaction/' || LOWER(TO_HEX(FROM_BASE64(E.trace_id))),
    DATE_FORMAT(E.block_time, '%Y-%m-%d %H:%i')
) AS sale_time

-- User wallet link (non-bounceable UQ for real users)
GET_HREF(
    'https://tonviewer.com/' || ton_address_raw_to_user_friendly(E.owner_address, false),
    SUBSTR(ton_address_raw_to_user_friendly(E.owner_address, false), 1, 6) || '...' || SUBSTR(ton_address_raw_to_user_friendly(E.owner_address, false), -4)
) AS buyer

-- Smart contract link (bounceable EQ — default)
GET_HREF(
    'https://tonviewer.com/' || ton_address_raw_to_user_friendly(m.source),
    SUBSTR(ton_address_raw_to_user_friendly(m.source), 1, 6) || '...' || SUBSTR(ton_address_raw_to_user_friendly(m.source), -4)
) AS contract
```
