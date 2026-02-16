# TONAPI Reference

REST API for TON blockchain data. Useful for cross-verifying Dune aggregations, real-time data, and debugging.

## API Access

```bash
# Auth header
Authorization: Bearer $TONAPI_KEY

# Get transactions for an address (deduplicated)
curl -H "Authorization: Bearer $TONAPI_KEY" \
  "https://tonapi.io/v2/blockchain/accounts/{address}/transactions?limit=100"
```

API key stored in `$TONAPI_KEY` environment variable.

## When to Use

- **Cross-verify Dune aggregations** — TONAPI returns deduplicated data. If your Dune SUM is 2x what TONAPI shows, you forgot `direction = 'in'`
- **Real-time data** — Dune may lag behind the chain
- **Exact transaction counts** — verify totals for specific addresses
- **Debugging doubled numbers** — quick sanity check

## Rate Limits

- **Free tier:** 1 RPS
- **Cache all responses to JSON** — 1000 addresses = ~20 min fetch time at 1 RPS
- For bulk address tagging, use ton-profiler batch endpoint: `POST /api/v1/addresses/tags` (max 200 per request)
