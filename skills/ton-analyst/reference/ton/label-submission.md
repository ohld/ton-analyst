# ton-labels Submission Guide

## What We Label

- Companies, exchanges, apps, games, DeFi protocols, bridges, validators
- Any **entity** that operates on the TON blockchain
- Multiple addresses per entity are fine (hot wallet, withdrawal wallet, contracts, etc.)

## What We DON'T Label

- Personal wallets of individual people (even if they move large amounts)
- Addresses where we can't identify the operating entity
- Addresses with only circumstantial evidence and no confirmed entity link
- Validator or wallet ownership inferred only from CEX, bridge, merchant, or generic service funding

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
- **Cluster analysis**: on-chain graph analysis shows the address in the same funding cluster as labelled addresses

### What Does NOT Count as Proof

- "This address interacts with Entity X" — many addresses interact with popular services
- "Funded from Binance" — millions of addresses are funded from Binance
- "Funded from a bridge, merchant, or CEX" — this shows liquidity provenance, not operator ownership
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

## Submitting a PR

1. Fork or branch from `ton-studio/ton-labels`
2. Add/update JSON files in `assets/{category}/`
3. Run `python3 build_assets.py` — must pass
4. Create PR with:
   - **Summary**: which entities, how many addresses
   - **For each address**: clickable proof links (tonviewer transactions, account pages)
   - Use markdown links: `[EQxxxx](https://tonviewer.com/EQxxxx)`

Read the [README](https://github.com/ton-studio/ton-labels/blob/main/README.md) for the full contribution guide.
