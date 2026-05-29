# Update Flow

ton-analyst ships as both a Claude Code marketplace plugin and a portable skill
directory for Codex/local agents. Every invocation runs a small bootstrap before
analysis starts: check the public `VERSION`, update the local skill when a newer
version exists, then continue the requested work.

## Version Sources

- Published plugin version: `.claude-plugin/marketplace.json`
- Runtime skill version: `skills/ton-analyst/VERSION`
- Skill frontmatter: `skills/ton-analyst/SKILL.md`

CI requires all three to match. Claude Code uses the marketplace/plugin version
as the cache key, so releases must bump the explicit version before users can
receive the changed plugin.

Most PRs do not need to edit these version files. After a PR is merged into
`main`, `.github/workflows/bump-version-on-main.yml` increments the patch version
unless that push already changed `VERSION`. This keeps reference updates
publishable without manual version edits in every PR.
The workflow skips based on the GitHub Actions bot actor and actual `VERSION`
file changes, not commit-message markers.

First-run caveat: versions before 0.4.10 have no update check. Non-git users on
0.4.10/0.4.11 need one host-native update to receive archive auto-update. After
that, future releases are applied from inside the skill.

## Runtime Bootstrap

Every skill invocation runs `bin/ton-analyst-bootstrap` from the installed skill
directory. The preamble resolves the directory in this order:

1. `TON_ANALYST_SKILL_DIR` override
2. `CLAUDE_SKILL_DIR` for Claude Code plugin/personal skills
3. `${CODEX_HOME:-~/.codex}/skills/ton-analyst`
4. project-local `.agents/skills/ton-analyst`
5. `~/.agents/skills/ton-analyst`
6. `~/.claude/skills/ton-analyst`
7. `./skills/ton-analyst` for repo-root development

The bootstrap calls `bin/ton-analyst-update-check`, which fetches:

```
https://raw.githubusercontent.com/ohld/ton-analyst/main/skills/ton-analyst/VERSION
```

The checker prints `UPDATE_AVAILABLE <old> <new>` only when the remote version
is greater than the local version. It is silent when up to date, offline,
disabled, or cache-fresh. `--json` emits a stable object for tests and wrappers.

When an update is available, the bootstrap calls `bin/ton-analyst-upgrade`.
Auto-update is enabled by default. Set `TON_ANALYST_AUTO_UPDATE=0|false|off`
only to pin a local copy temporarily. Successful upgrades print:

```
UPDATED <old> <new> <skill_dir>
```

The skill should then briefly tell the user it updated, read the fresh
`<skill_dir>/SKILL.md` when available, and continue with the requested analysis.

## Cadence

State lives in `${TON_ANALYST_STATE_DIR:-~/.ton-analyst}`.

- Up to date cache: 60 minutes
- Update available cache: 12 hours
- Disable per run/session: `TON_ANALYST_UPDATE_CHECK=0`
- Disable auto-update but keep notification: `TON_ANALYST_AUTO_UPDATE=0`
- Force re-check: `bin/ton-analyst-bootstrap --force`

## Default Auto-Update

Git-backed installs use a fast-forward pull when safe:

- repo root must be a git checkout
- `origin` must point to `github.com/ohld/ton-analyst`
- current branch must be `main`
- worktree must be clean
- `HEAD` must be fast-forwardable to `origin/main`

Plain copied/plugin installs download the GitHub archive for `main`, verify
`VERSION`, back up the current skill directory under
`${TON_ANALYST_STATE_DIR:-~/.ton-analyst}/backups/`, then replace files in place
while preserving `.venv`.

Dirty worktrees, forks, feature branches, detached heads, non-fast-forward git
states, missing tools, and unwritable copied installs are skipped. Skip markers
look like:

```
UPDATE_AVAILABLE <old> <new> AUTO_UPDATE_SKIPPED dirty_worktree
```

The upgrader does not run `skills/ton-analyst/setup` during bootstrap, so it
will not install `uv` or mutate the CLI venv as a side effect. Existing CLI
users can rerun setup manually after an update when dependencies change.

## Host Update Paths

### Claude Code Install

```
/plugin marketplace add ohld/ton-analyst
/plugin install ton-analyst@ton-analyst
```

### Claude Code Update

```
/plugin marketplace update ton-analyst
/plugin update ton-analyst@ton-analyst
/reload-plugins
```

### Codex Install

Codex reads skills from `${CODEX_HOME:-~/.codex}/skills`. From the cloned repo:

```
./setup --host codex
```

Then relaunch Codex so it reloads the skill.

### Codex / Local Git Update

```
git -C /path/to/ton-analyst pull --ff-only
```

Bootstrap handles safe git installs and copied/plugin installs automatically.
Manual update remains useful for first install, forks, dirty worktrees, and
hosts that cache skill files until restart. New local installs can use
`./setup --host codex`, `./setup --host agents`, or `./setup --host claude`.

## Release Checklist

1. Update docs/references.
2. For normal PRs, do not bump version files manually; let the main-push workflow bump patch after merge.
3. For intentional release PRs, bump `.claude-plugin/marketplace.json`, `SKILL.md`, and `VERSION` together.
4. Add `CHANGELOG.md` notes.
5. Run validation and open/merge the PR.
