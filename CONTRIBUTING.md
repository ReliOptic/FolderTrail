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
- test plan,
- out-of-scope decisions.

For v0.1, follow the dependency map in [`docs/ISSUE_MAP.md`](docs/ISSUE_MAP.md). Do not bundle unrelated milestones into one PR. If a QA pass finds new work, create or update an issue instead of silently expanding the current PR.

Use [`docs/IMPLEMENTATION_STATUS.md`](docs/IMPLEMENTATION_STATUS.md) as the current public status ledger and [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md) as the GitHub maintenance contract. If a PR changes implementation completeness, release readiness, provider/auth behavior, safety behavior, or documentation truth, update the status ledger in the same PR.

### 3. Branch and open a draft PR early

Use one focused branch per issue. Each issue should be an independently reviewable vertical slice with clear blockers, not a vague phase of a large plan:

```text
issue-<number>-<short-slug>
```

Open a draft PR once the first test or skeleton exists. The PR is the development reference: record decisions, RED/GREEN evidence, screenshots when useful, and remaining gaps there.

Mark tasks that require human judgement, credentials, signing, or visual taste as HITL. Keep autonomous tasks small enough that an agent can complete them inside one focused context.

After the PR is merged, delete the issue branch. Deleting the branch only removes the temporary pointer; the PR, commits, discussion, issue timeline, and release-note references remain on GitHub.

### 4. Use small TDD loops

Prefer one vertical slice at a time:

```text
RED: write one behavior test and watch it fail
GREEN: add the smallest implementation that passes
REFACTOR: simplify while tests stay green
```

Tests should describe public behavior, not private implementation details. Prefer deep modules: small public interfaces with meaningful behavior behind them, tested from the outside. If a behavior is hard to test, improve the feedback loop before adding more implementation.

### 5. Prove done with acceptance evidence

Done means verified acceptance. Do not call a PR or issue done just because tests passed or the branch merged.

For each issue, collect acceptance evidence that proves the promised user-visible behavior:

- RED evidence: the first focused behavior test failed for the right reason.
- GREEN evidence: the focused behavior test passed after the smallest implementation.
- Acceptance evidence: the issue acceptance criteria were checked against the app behavior.
- Smoke evidence: UI, Finder, auth, packaging, or workflow changes include a manual or scripted smoke check when locally possible.
- Known gaps: anything not verified is named plainly in the PR and issue comment.

If user-visible behavior was not verified, say “not verified yet” and keep the issue open or create a follow-up issue. Do not hide unverified work behind a successful unit test, merge, or generated artifact.

### 6. Review and merge

Before marking a PR ready:

- map the PR back to the issue acceptance criteria,
- review the tests first, then the implementation,
- paste verification commands and results,
- manually QA user-visible flows when UI or Finder behavior changes,
- call out known gaps honestly,
- keep the diff small enough to review.

After merge, close the issue with a short summary and link the PR.

## Keep records lightweight

Use issues and PRs as the durable history for planning, trade-offs, and TDD evidence. Avoid keeping stale one-off planning documents in the repo after the work is complete; convert lasting decisions into product docs, architecture docs, or follow-up issues instead.

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
- [ ] RED evidence: one behavior test failed for the right reason
- [ ] GREEN evidence: the same behavior passed after the implementation
- [ ] Covers user-visible behavior through public interfaces
- [ ] Acceptance evidence: issue criteria checked against behavior
- [ ] Manual or scripted smoke check included when UI/Finder/auth/workflow behavior changed
- [ ] Includes verification evidence
- [ ] Known gaps or follow-ups are called out explicitly
