# FolderTrail agent notes

This file is for coding agents working in this repository. Human-facing contribution guidance lives in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## v0.1 issue workflow

For FolderTrail v0.1 implementation:

- Work one GitHub issue at a time.
- Start from latest `main` and create `issue-<number>-<short-slug>`.
- Use TDD: RED → GREEN → REFACTOR, one vertical slice at a time.
- Shape issues as independently reviewable vertical slices with explicit blockers.
- Open or update one PR per issue and keep development evidence in the PR body/comments.
- Do not batch unrelated issues into one branch or PR.
- Do not say done unless acceptance evidence proves the user-visible behavior works.
- If the user-visible flow was not verified, say what remains unverified.
- Keep context small; use fresh review/QA passes instead of reviewing in the same long implementation context.
- Record out-of-scope decisions in issues/PRs, not stale one-off repo docs.
- After merge, delete the issue branch; GitHub keeps the PR, commits, discussion, and issue timeline.
- Follow the dependency order in `docs/ISSUE_MAP.md` unless a blocker requires a smaller prerequisite PR.

## Safety invariants

- Never mutate the original selected folder.
- Perform file operations only in the copied workspace.
- Reject paths outside the workspace boundary.
- Do not delete files; move delete candidates to review instead.
- Verify with the smallest useful test first, then broader checks when available.
- Prefer deep modules with small public interfaces and meaningful behavior tested from the outside.
- Manually QA user-visible UI/Finder flows; convert QA findings into follow-up issues when they expand scope.
