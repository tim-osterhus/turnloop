#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class RepoState:
    path: str
    branch: str
    dirty: bool
    needs_push: bool
    ahead: int | None
    behind: int | None
    upstream: str | None
    status: list[str]


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=check,
        text=True,
        capture_output=True,
    )


def discover_repos(root: Path) -> list[Path]:
    repos: set[Path] = set()
    for current, dirs, _files in os.walk(root):
        dirs[:] = [name for name in dirs if name != ".git"]
        path = Path(current)
        if (path / ".git").exists():
            repos.add(path.resolve())
    return sorted(repos, key=lambda path: (len(path.parts), str(path)))


def repo_state(repo: Path, root: Path) -> RepoState:
    status_lines = git(repo, "status", "--short").stdout.splitlines()
    branch = git(repo, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()

    upstream: str | None = None
    ahead: int | None = None
    behind: int | None = None
    needs_push = False

    upstream_result = git(
        repo,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{u}",
        check=False,
    )
    if upstream_result.returncode == 0:
        upstream = upstream_result.stdout.strip()
        counts_result = git(repo, "rev-list", "--left-right", "--count", "@{u}...HEAD")
        behind_str, ahead_str = counts_result.stdout.strip().split()
        behind = int(behind_str)
        ahead = int(ahead_str)
        needs_push = ahead > 0

    rel_path = repo.resolve().relative_to(root.resolve())
    display_path = "." if str(rel_path) == "." else rel_path.as_posix()

    return RepoState(
        path=display_path,
        branch=branch,
        dirty=bool(status_lines),
        needs_push=needs_push,
        ahead=ahead,
        behind=behind,
        upstream=upstream,
        status=status_lines,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Enumerate git repos in a workspace.")
    parser.add_argument("--root", default=".", help="Workspace root to scan")
    parser.add_argument(
        "--changed-only",
        action="store_true",
        help="Only emit repos that are dirty or ahead of upstream",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print JSON output",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    repos = [repo_state(repo, root) for repo in discover_repos(root)]
    if args.changed_only:
        repos = [repo for repo in repos if repo.dirty or repo.needs_push]

    payload = [asdict(repo) for repo in repos]
    json.dump(payload, fp=os.sys.stdout, indent=2 if args.pretty else None)
    os.sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
