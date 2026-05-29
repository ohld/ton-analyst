# Skill Architecture Refactor Proposal

Goal: keep `ton-analyst` easy for agents to invoke while making its reference
knowledge denser, easier to lazy-load, and safer to maintain.

This proposal builds on [`docs/professionalization-plan.md`](professionalization-plan.md)
and intentionally narrows the next step. It is not a full rewrite.

## Inputs Reviewed

- `ton-analyst` v0.4.10 on `origin/main`
- [OpenAI skills catalog](https://github.com/openai/skills)
- [OpenAI Codex skills docs](https://developers.openai.com/codex/skills)
- [Claude Code skills docs](https://code.claude.com/docs/en/skills)
- [garrytan/gbrain](https://github.com/garrytan/gbrain)
- [garrytan/gstack](https://github.com/garrytan/gstack)

## Lessons To Reuse

- Codex/OpenAI: keep `SKILL.md` as the entrypoint; put long domain knowledge in
  `reference/`, deterministic helpers in scripts, and optional product metadata
  in `agents/openai.yaml`.
- Claude Code: use progressive disclosure. The skill body should route the
  agent; support files carry the details.
- GBrain: use clear routing metadata, small conventions files, and explicit
  "source of truth vs reference copy" rules.
- GStack: update checks should be stable and small; mutation-heavy upgrade flows
  need install-type detection, snooze/disable controls, and tests.

## Current Gaps

- `SKILL.md` is acceptable at 148 lines, but still contains reference-like table
  and convention summaries.
- Three reference files are too large for efficient use:
  - `reference/dune/query-patterns.md` has 370 lines.
  - `reference/ton/address-investigation.md` has 251 lines.
  - `reference/ton/labels.md` has 186 lines.
- `reference/index.md` exists, but it should become the single routing surface:
  task -> read first -> optional follow-up -> example SQL.
- There is no simple CI gate for broken local links, oversized reference files,
  or stale paths after reference splits.

## Knowledge Ownership

`ton-analyst` remains the source-of-truth knowledge base for how TON works and
how TON data is queried through Dune, TONAPI, labels, and report workflows.

GBrain can store distilled decisions, links, and retrieval briefings in a
TON-related vault, but this proposal does not bulk-migrate the TON reference
corpus into GBrain.

## Proposed Next PR

Make the reference layer more lazy-loadable without changing runtime behavior.

1. Keep `SKILL.md` as a gateway.
   - Keep the update-check preamble, routing rule, hard report contract, and
     a few critical invariants.
   - Move detailed table lists and secondary conventions into narrow references.

2. Strengthen `reference/index.md`.
   - Add rows for common tasks: wallet investigation, CEX flows, supply,
     staking, NFT/Fragment, jettons, priority mining, trading-bot adoption, and
     report generation.
   - Each row should name the smallest first file to read, optional follow-ups,
     and example SQL when available.

3. Split only the oversized files.
   - Split `dune/query-patterns.md` into focused files, but leave
     `query-patterns.md` as a short router/stub so existing links keep working.
   - Split `ton/address-investigation.md` into wallet investigation, label proof
     rules, funder tracing, and CLI/TONAPI lookup, again leaving a compatibility
     stub.
   - Split `ton/labels.md` into label sources, entity classification, and
     Fragment-specific mechanics, leaving a compatibility stub.

4. Preserve existing paths during the split.
   - Any file currently linked from `SKILL.md`, `README.md`, or existing
     references either keeps its path or becomes a stub with links to the new
     files.
   - Update all internal links in the same PR.

5. Add simple validation.
   - Check local Markdown links under `skills/ton-analyst/`.
   - Check that ordinary reference files stay below the agreed line budget, or
     have a table of contents and an explicit reason to remain long.
   - Do not add generated manifests yet.

## Defer

- Do not implement automatic upgrade in the reference refactor PR.
- First harden the existing update checker with JSON output, `ton doctor`, dirty
  worktree refusal, dry-run behavior, explicit `--yes`, symlink handling, and
  tests. Only then consider opt-in auto-update.
- Do not add `reference/manifest.json` or frontmatter generation until routing
  fixtures need machine-readable metadata.
- Do not add a generated-template system unless duplication becomes a real
  maintenance problem.
- Do not split `ton-analyst` into many separate skills yet. TON analysis often
  mixes Dune, TONAPI, labels, and reporting, so one gateway skill with a strong
  router is less fragile.
- Do not move `ton` CLI internals in this refactor; that belongs to the CLI
  architecture work in the professionalization plan.
- Do not migrate the full TON knowledge base into GBrain. Use GBrain as a
  retrieval and briefing layer.

## Taxonomy

Avoid creating duplicate homes for durable rules:

- Use `CONTEXT.md` for domain terms and rejected synonyms.
- Use `docs/adr/` for durable architecture decisions.
- Use `reference/report-format.md` for report output requirements.
- Use narrow `reference/` files for operational analysis patterns.
- Keep the existing singular `reference/` directory for compatibility, even
  though some generic skill examples use `references/`.

## Success Criteria

- `SKILL.md` stays below 150 lines.
- Existing public paths do not break.
- A new analyst task can start from `reference/index.md` and load only two or
  three focused files.
- The first PR contains only routing/reference reshaping and simple validation.
- Update automation and generated manifests are explicitly deferred.
