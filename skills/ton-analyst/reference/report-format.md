# Report Format

Every research report MUST:

1. **Use tonviewer hyperlinks for addresses.** Truncated display is fine only
   when the URL contains the full address:
   `[0:ED16...F8A7](https://tonviewer.com/0:ED1691307050047117B998B561D8DE82D31FBF84910CED6EB5FC92E7485EF8A7)`.
   Bare truncated addresses are unverifiable.
2. **Save query logs** alongside the report: every SQL query and result snapshot
   in a `queries/` subfolder, such as `queries/01-outflows.sql` and
   `queries/01-outflows.json`.
3. **Include methodology:** tables used, date ranges, hop depth, filters,
   classification logic, excluded entities, confidence level, and blind spots.
4. **Name inference clearly.** If a label, owner, volume, or intent is inferred
   rather than directly observed, say so.
5. **Keep TON and jettons separate** unless converting with an explicit price
   source and timestamp.

For Dune dashboards, prefer clickable datetime columns with `GET_HREF()` so the
viewer can inspect the exact transaction without extra table columns.
