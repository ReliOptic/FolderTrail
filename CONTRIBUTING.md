# Contributing to FolderTrail

FolderTrail is a small, local-first macOS app. Keep the contribution flow lightweight, public, and easy to follow.

## Contribution flow

```text
Issue idea
→ Design / spec alignment
→ Branch & PR
→ Review & merge
→ Release notes
```

### 1. Open or pick an issue

Use GitHub issues for bugs, feature ideas, UX improvements, and documentation updates.

A good issue says:

- what problem it solves,
- what user-visible behavior should change,
- how we can verify it,
- whether it touches safety-sensitive file operations.

### 2. Align on the design

Before coding, keep the design note short:

- acceptance criteria,
- UI/UX impact,
- safety invariants,
- test plan.

For v0.1, follow the dependency map in [`docs/ISSUE_MAP.md`](docs/ISSUE_MAP.md). Do not bundle unrelated milestones into one PR.

### 3. Branch and open a draft PR early

Use one focused branch per issue:

```text
issue-<number>-<short-slug>
```

Open a draft PR once the first test or skeleton exists. The PR is the development reference: record decisions, RED/GREEN evidence, screenshots when useful, and remaining gaps there.

### 4. Use small TDD loops

Prefer one vertical slice at a time:

```text
RED: write one behavior test and watch it fail
GREEN: add the smallest implementation that passes
REFACTOR: simplify while tests stay green
```

Tests should describe public behavior, not private implementation details.

### 5. Review and merge

Before marking a PR ready:

- map the PR back to the issue acceptance criteria,
- paste verification commands and results,
- call out known gaps honestly,
- keep the diff small enough to review.

After merge, close the issue with a short summary and link the PR.

## v0.1 issue order

The current v0.1 path is documented in [`docs/ISSUE_MAP.md`](docs/ISSUE_MAP.md):

1. Repo foundation
2. macOS app bootstrap
3. Finder service entry
4. provider connection
5. floating prompt
6. preflight check
7. consent modal
8. safe workspace copy
9. manifest builder
10. planner adapter
11. safe executor
12. compact status state machine
13. trail writer and done state
14. signed/notarized distribution

## Verification

Use the smallest checks that prove the behavior, then broader checks when available.

Common local checks for the macOS app:

```bash
python3 -m unittest discover tests
xmllint --noout app/macos/FolderTrail.xcodeproj/xcshareddata/xcschemes/*.xcscheme
plutil -lint app/macos/FolderTrail/Info.plist app/macos/FolderTrail/FolderTrail.entitlements app/macos/FolderTrail.xcodeproj/project.pbxproj
swiftc -warnings-as-errors -target arm64-apple-macosx14.0 <changed swift files> -o build/FolderTrailSmoke
xcodebuild -project app/macos/FolderTrail.xcodeproj -scheme FolderTrail -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

If a check cannot run locally, paste the exact reason in the PR.

## Safety rules

FolderTrail works with user folders, so safety is part of every contribution:

- never mutate the original selected folder,
- perform AI/file operations only in the copied workspace,
- reject paths outside the workspace boundary,
- do not delete files; move delete candidates to review instead,
- keep trail artifacts understandable.

## PR checklist

- [ ] Links the issue
- [ ] Shows the RED/GREEN loop or explains why it is docs-only
- [ ] Covers user-visible behavior through public interfaces
- [ ] Includes verification evidence
- [ ] Calls out known gaps or follow-ups
