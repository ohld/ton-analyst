#!/usr/bin/env python3
"""Validate ton-analyst skill structure."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = REPO_ROOT / "skills" / "ton-analyst"
REFERENCE_DIR = SKILL_DIR / "reference"
MAX_MD_LINES = 150

LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
EXTERNAL_SCHEMES = {
    "http",
    "https",
    "mailto",
    "tel",
}


def iter_markdown_files() -> list[Path]:
    return [
        REPO_ROOT / "README.md",
        SKILL_DIR / "SKILL.md",
        *sorted(REFERENCE_DIR.rglob("*.md")),
    ]


def strip_code_fences(text: str) -> str:
    lines: list[str] = []
    in_fence = False
    for line in text.splitlines():
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            lines.append(line)
    return "\n".join(lines)


def target_path(source: Path, raw_target: str) -> Path | None:
    target = raw_target.strip()
    if not target or target.startswith("#"):
        return None

    parsed = urlsplit(target)
    if parsed.scheme in EXTERNAL_SCHEMES or parsed.netloc:
        return None
    if parsed.scheme and parsed.scheme not in {"file"}:
        return None

    path_part = unquote(parsed.path)
    if not path_part or path_part.startswith("#"):
        return None
    if path_part.startswith("/"):
        return None

    return (source.parent / path_part).resolve()


def check_line_budgets(errors: list[str]) -> None:
    skill_lines = (SKILL_DIR / "SKILL.md").read_text().count("\n")
    if skill_lines > MAX_MD_LINES:
        errors.append(f"SKILL.md has {skill_lines} lines; max is {MAX_MD_LINES}")

    for path in sorted(REFERENCE_DIR.rglob("*.md")):
        lines = path.read_text().count("\n")
        if lines > MAX_MD_LINES:
            rel = path.relative_to(REPO_ROOT)
            errors.append(f"{rel} has {lines} lines; max is {MAX_MD_LINES}")


def check_required_files(errors: list[str]) -> None:
    required = [
        SKILL_DIR / "bin" / "ton-analyst-bootstrap",
        SKILL_DIR / "bin" / "ton-analyst-update-check",
        SKILL_DIR / "bin" / "ton-analyst-upgrade",
        REFERENCE_DIR / "index.md",
        REFERENCE_DIR / "report-format.md",
        REFERENCE_DIR / "dune" / "query-patterns.md",
        REFERENCE_DIR / "dune" / "patterns" / "gotchas.md",
        REFERENCE_DIR / "dune" / "patterns" / "labels-real-users.md",
        REFERENCE_DIR / "dune" / "patterns" / "address-classification.md",
        REFERENCE_DIR / "dune" / "patterns" / "nft-fragment.md",
        REFERENCE_DIR / "dune" / "patterns" / "sql-conventions.md",
        REFERENCE_DIR / "dune" / "patterns" / "comment-analysis.md",
        REFERENCE_DIR / "ton" / "labels.md",
        REFERENCE_DIR / "ton" / "key-addresses.md",
        REFERENCE_DIR / "ton" / "fragment.md",
        REFERENCE_DIR / "ton" / "address-investigation.md",
        REFERENCE_DIR / "ton" / "wallet-investigation.md",
        REFERENCE_DIR / "ton" / "label-submission.md",
    ]
    for path in required:
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(REPO_ROOT)}")


def check_markdown_links(errors: list[str]) -> None:
    for source in iter_markdown_files():
        text = strip_code_fences(source.read_text())
        for match in LINK_RE.finditer(text):
            raw_target = match.group(1).split(None, 1)[0]
            path = target_path(source, raw_target)
            if path is None:
                continue
            if not path.exists():
                errors.append(
                    f"broken link in {source.relative_to(REPO_ROOT)}: {match.group(1)}"
                )


def main() -> int:
    errors: list[str] = []
    check_required_files(errors)
    check_line_budgets(errors)
    check_markdown_links(errors)

    if errors:
        print("Skill validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("OK: skill structure, line budgets, and markdown links")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
