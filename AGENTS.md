# FolderTrail agent notes

This file is for coding agents working in this repository. Human-facing contribution guidance lives in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## v0.1 issue workflow

For FolderTrail v0.1 implementation:

- Work one GitHub issue at a time.
- Start from latest `main` and create `issue-<number>-<short-slug>`.
- Use TDD: RED → GREEN → REFACTOR, one vertical slice at a time.
- Open or update one PR per issue and keep development evidence in the PR body/comments.
- Do not batch unrelated issues into one branch or PR.
- After merge, delete the issue branch; GitHub keeps the PR, commits, discussion, and issue timeline.
- Follow the dependency order in `docs/ISSUE_MAP.md` unless a blocker requires a smaller prerequisite PR.

## Safety invariants

- Never mutate the original selected folder.
- Perform file operations only in the copied workspace.
- Reject paths outside the workspace boundary.
- Do not delete files; move delete candidates to review instead.
- Verify with the smallest useful test first, then broader checks when available.
