-- Filter by Contract Interface
--
-- Question: How to exclude jetton_wallet / nft_item contracts from analysis?
-- Pattern: array_position(interfaces, 'X') = 0 excludes interface X
-- Works for: jetton_wallet, jetton_master, nft_item, nft_collection, etc.

SELECT T.*
FROM ton.transactions T
INNER JOIN ton.accounts A ON A.address = T.account
WHERE array_position(A.interfaces, 'jetton_wallet') = 0
  AND T.block_date >= DATE '2026-01-01'
LIMIT 50
