# FolderTrail v0.1 TDD Release Strategy

FolderTrail v0.1 is delivered by closing GitHub issues one dependency-safe vertical slice at a time. Each slice must leave enough public evidence for a future maintainer to understand: what was promised, what test failed first, what code made it pass, what was verified, and what risk remains.

## Operating rule

**One issue, one branch, one draft PR, one TDD ledger.**

Do not batch unrelated milestones into one PR. If a later issue is blocked, finish and merge the blocker first.

## Issue order

Use the dependency order in `docs/ISSUE_MAP.md`:

1. #1 Repo Foundation
2. #2 Project Bootstrap
3. #3 Finder Service Entry
4. #4 Provider Connect
5. #5 Floating Prompt
6. #6 Preflight Check
7. #7 Consent Modal
8. #8 Copy Workspace
9. #9 Adaptive Manifest Builder
10. #10 OpenRouter Planner Adapter
11. #11 Safe Executor
12. #12 Compact Status State Machine
13. #13 Trail Writer + Done State
14. #14 Distribution — Developer ID + Notarization

When two issues are both unblocked, prefer the one that unlocks the most downstream work. For v0.1 this usually means following the list above.

## Per-issue workflow

### 1. Intake

- Read the GitHub issue body and acceptance criteria.
- Confirm blockers are closed or already satisfied locally.
- Map acceptance criteria to observable behavior through public interfaces.
- Create a branch named `issue-<number>-<short-slug>`.
- Open a draft PR early, before implementation is complete.

### 2. TDD ledger

Every PR must maintain a short ledger in the PR body:

```text
TDD Ledger
- RED 1: <behavior test added> -> <failure evidence>
- GREEN 1: <minimal implementation> -> <passing evidence>
- REFACTOR 1: <simplification, if any> -> <passing evidence>
```

Use vertical slices. Do not write all tests first and then all implementation.

### 3. GitHub trace

Use **PR comments as the canonical step-by-step development reference** once a PR exists. Use issue comments only for milestone-level status or blockers.

Recommended comment cadence:

- Issue comment when starting an issue:
  - branch name
  - draft PR link, if already available
  - first TDD target
- PR comment after each meaningful TDD cycle:
  - RED evidence
  - GREEN evidence
  - changed files
  - next cycle
- Issue comment when closing:
  - PR link
  - verification evidence
  - any follow-up issue numbers

### 4. Verification gate

Before marking a PR ready for review, run the smallest checks that prove the issue acceptance criteria, then broader checks where available.

For Swift/macOS app work:

```bash
python3 -m unittest discover tests
xmllint --noout app/macos/FolderTrail.xcodeproj/xcshareddata/xcschemes/*.xcscheme
plutil -lint app/macos/FolderTrail/Info.plist app/macos/FolderTrail/FolderTrail.entitlements app/macos/FolderTrail.xcodeproj/project.pbxproj
swiftc -warnings-as-errors -target arm64-apple-macosx14.0 <changed swift files> -o build/FolderTrailSmoke
xcodebuild -project app/macos/FolderTrail.xcodeproj -scheme FolderTrail -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

If full `xcodebuild` cannot run because only Command Line Tools are installed, record that as `Not-tested` and include the exact error.

### 5. Merge/close gate

An issue can be closed only when:

- all issue acceptance criteria are either satisfied or explicitly moved to a follow-up issue,
- tests include at least one failing-before-passing behavior check,
- verification evidence is recorded in the PR,
- the PR is merged,
- a final issue comment links the merged PR and verification summary.

## Branching and PR policy

| Scope | Branch | PR style |
|---|---|---|
| One issue | `issue-<n>-<slug>` | Draft PR opened early |
| Small follow-up | `issue-<n>-followup-<slug>` | Separate PR only if review clarity improves |
| HITL signing/distribution | `issue-14-distribution` | Draft until human checkpoints complete |

Avoid long-lived mega-branches. Use stacked PRs only when GitHub dependencies are clear in the PR body.

## Commit protocol

All commits follow the repo Lore Commit Protocol in `AGENTS.md`. Minimum useful trailers:

```text
Confidence: high|medium|low
Scope-risk: narrow|moderate|broad
Tested: <commands/evidence>
Not-tested: <known gap>
```

## TDD templates

### Start issue comment

```markdown
Starting TDD work for this issue.

- Branch: `issue-<n>-<slug>`
- Draft PR: <link or "opening after first RED/GREEN cycle">
- First vertical slice: <behavior>
- Initial verification target: <command/test>
```

### PR TDD cycle comment

```markdown
TDD cycle <n>

- RED: <test name / behavior> failed as expected: `<short failure>`
- GREEN: implemented <minimal change>
- Evidence: `<command>` passed
- Files touched: <paths>
- Next: <next behavior or ready-for-review gate>
```

### Close issue comment

```markdown
Completed via PR <link>.

Verification:
- `<command>`: passed
- `<command>`: passed

Known gaps:
- <none or explicit follow-up>
```

## v0.1 stop condition

v0.1 is complete when #1-#13 are closed by merged PRs and #14 has passed its human checkpoints:

- Developer ID Application certificate selected
- app notarized and stapled
- Gatekeeper assessment passes on a clean Mac
- README install instructions are current
