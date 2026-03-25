# ton.accounts

Current state of all TON accounts.

| Column | Type | Notes |
|--------|------|-------|
| address | string | Raw format (`0:...` or `-1:...`) |
| interfaces | array(string) | Prepopulated by Dune from known `code_hash` → interface mappings (e.g. `jetton_wallet`, `wallet_v4r2`, `nft_item`). Not all contracts are decoded — use `code_hash` directly for uncommon types. |
| balance | bigint | Current balance in nanoTON (divide by 1e9) |
| status | string | `active`, `uninit`, `nonexist`, `frozen` |
| deployment_at | timestamp | When account was deployed |
| last_tx_at | timestamp | Last transaction time |
| first_tx_sender | string | Address that initiated first tx to this account |
| code_hash | string | Base64-encoded contract code hash |

**Status gotcha:** Early miners = `status='uninit'` (NOT `frozen`). The `frozen` status has only 31 addresses with ~0 TON.

**Known wallet interfaces:** `wallet_v3r2`, `wallet_v4r2`, `wallet_v5r1`, `wallet_highload_v3r1` (high-throughput, used by some CEXes — but NOT a CEX indicator on its own).

**Interface patterns:**
```sql
-- Is wallet?
cardinality(FILTER(interfaces, i -> regexp_like(i, '^wallet_'))) > 0
-- Is multisig?
cardinality(FILTER(interfaces, i -> regexp_like(i, '^multisig'))) > 0
-- Is nominator pool? (catches masterchain + basechain)
cardinality(FILTER(interfaces, i -> i = 'validation_nominator_pool')) > 0
-- Exclude jetton wallets
array_position(A.interfaces, 'jetton_wallet') = 0
```
