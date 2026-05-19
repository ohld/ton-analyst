# Update Flow

ton-analyst ships as both a Claude Code marketplace plugin and a portable skill
directory that can be used by Codex/local agents. The update check is deliberately
small: shell emits a stable marker, and the skill text decides what to tell the
user.

## Version Sources

- Published plugin version: `.claude-plugin/marketplace.json`
- Runtime skill version: `skills/ton-analyst/VERSION`
- Skill frontmatter: `skills/ton-analyst/SKILL.md`

CI requires all three to match. Claude Code uses the marketplace/plugin version
as the cache key, so releases must bump the explicit version before users can
receive the changed plugin.

Most PRs do not need to edit these version files. After a PR is merged into
`main`, `.github/workflows/bump-version-on-main.yml` increments the patch version
unless that push already changed `VERSION`. This keeps small documentation and
reference updates publishable without manual version edits in every PR.

First-run caveat: users on versions before 0.4.0 do not have this checker yet.
They need one normal marketplace/local git update to receive 0.4.0; after that,
future releases are detected from inside the skill.

## Runtime Check

Every skill invocation runs `bin/ton-analyst-update-check` from the installed
skill directory. The preamble resolves the directory in this order:

1. `TON_ANALYST_SKILL_DIR` override
2. `CLAUDE_SKILL_DIR` for Claude Code plugin/personal skills
3. `${CODEX_HOME:-~/.codex}/skills/ton-analyst`
4. project-local `.agents/skills/ton-analyst`
5. `~/.agents/skills/ton-analyst`
6. `~/.claude/skills/ton-analyst`
7. `./skills/ton-analyst` for repo-root development

The checker fetches:

```
https://raw.githubusercontent.com/ohld/ton-analyst/main/skills/ton-analyst/VERSION
```

It prints `UPDATE_AVAILABLE <old> <new>` only when the remote version is greater
than the local version.
It is silent when up to date, offline, disabled, or cache-fresh.

## Cadence

State lives in `~/.ton-analyst/last-update-check`.

- Up to date cache: 60 minutes
- Update available cache: 12 hours
- Disable per run/session: `TON_ANALYST_UPDATE_CHECK=0`
- Force re-check: `bin/ton-analyst-update-check --force`

## User Flow

When `UPDATE_AVAILABLE` appears, the agent should mention the update briefly and
continue the requested analysis unless the user asks to update first.

Claude Code marketplace install:

```
/plugin marketplace update ton-analyst
/plugin update ton-analyst@ton-analyst
/reload-plugins
```

Codex or local git install:

```
git -C /path/to/ton-analyst pull --ff-only
```

Then relaunch the agent so it reloads the updated skill. If the `ton` CLI wrapper
was installed from this checkout, rerun `./skills/ton-analyst/setup` after pulling.
For new local installs, use `./setup --host codex`, `./setup --host agents`, or
`./setup --host claude`.

## Release Checklist

1. Update docs/references.
2. For normal PRs, do not bump version files manually; let the main-push workflow bump patch after merge.
3. For intentional release PRs, bump `.claude-plugin/marketplace.json`, `SKILL.md`, and `VERSION` together.
4. Add `CHANGELOG.md` notes.
5. Run validation and open/merge the PR.

## GStack Comparison

gstack uses explicit `VERSION` files too, but its `/ship` workflow chooses and
writes the next version before opening a PR. Its CI then checks that the PR's
claimed version is not stale versus other open PRs. ton-analyst uses a lighter
post-merge patch bump because most changes are reference updates and should not
require a manual version claim in every PR.
