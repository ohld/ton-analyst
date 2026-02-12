# Dune API & Research Workflow

## API Key

Stored in `$DUNE_API_KEY` environment variable (from `~/.zshrc`). Never hardcode in files.

**All queries must be PRIVATE** (never public). Always add `LIMIT 50` to exploratory queries.

## Execute Query

```bash
curl -X POST 'https://api.dune.com/api/v1/sql/execute' \
  -H "X-Dune-API-Key: ${DUNE_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT ... LIMIT 50"}'
```

Returns `execution_id`. Typical wait: 15-60s.

## Poll Results

```bash
curl "https://api.dune.com/api/v1/execution/${EXECUTION_ID}/results" \
  -H "X-Dune-API-Key: ${DUNE_API_KEY}"
```

Wait until `is_execution_finished: true` in the response.

## Formatting Rules

Don't multiply percentages by 100 or divide TON by 1e6 — Dune UI handles display formatting.

## Research Workflow

1. **Understand the question** — What metric? What time range? What filters?
2. **Plan CTEs** — Start with LABELS/REAL_USERS if filtering users. Check reference/patterns.md
3. **Write SQL** — Follow Presto/Trino syntax. Use `WHERE 1=1` + `AND` filters. Always filter `block_date` for partition pruning
4. **Execute on Dune** — Use API above. Poll until `is_execution_finished: true`
5. **Analyze results** — Look for outliers, compare with known facts (see reference/examples/supply-breakdown.sql)
6. **Report** — Structure findings with tables, key takeaways, caveats
