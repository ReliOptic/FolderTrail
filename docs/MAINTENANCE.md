# FolderTrail Maintenance Guide

_Last reviewed: 2026-06-15_

FolderTrail is small enough that maintenance should stay boring: GitHub issues describe the work, PRs carry the evidence, and repo docs preserve only durable product/architecture decisions.

---

## Maintenance goals

1. Keep implementation status visible from GitHub and the README.
2. Keep every user-visible claim tied to issue/PR evidence.
3. Prevent stale PRD wording from outranking current code and tests.
4. Keep release readiness separate from local implementation completeness.

---

## Canonical surfaces

| Surface | Purpose | Update when |
| --- | --- | --- |
| GitHub Issues | Work queue and blockers | Any bug, feature, release task, docs drift, or QA finding appears. |
| GitHub PRs | Evidence ledger | A branch changes code/docs; include verification and gaps before merge. |
| `docs/IMPLEMENTATION_STATUS.md` | Current milestone/release truth | User-visible behavior, provider/auth, safety, packaging, or release state changes. |
| `docs/DECISIONS.md` | Invariants extracted from tests/code | Tests encode or remove a product/architecture decision. |
| `docs/PHILOSOPHY.md` | Product philosophy and tensions | A decision changes the product's trust/safety/visibility stance. |
| `docs/ISSUE_MAP.md` | Historical v0.1 dependency map | Only if the v0.1 dependency structure itself changes; otherwise link to status. |

---

## Issue lifecycle

Use one focused issue per independently reviewable slice.

```text
needs-triage → scoped → in-progress → review/blocked → closed with evidence
```

Minimum issue fields:

- Problem / user-visible failure
- Acceptance criteria
- Safety impact, if any
- Verification plan
- AFK or HITL classification
- Related docs that must be updated

Do not close an issue only because code merged. Close it when the acceptance evidence is visible in the issue or linked PR.

---

## Label policy

Required labels:

- Milestone: `M1-entry`, `M2-provider`, `M3-workspace`, `M4-execution`, or `M5-ship`
- Work type: `bug`, `enhancement`, or `documentation`
- Execution mode: `AFK` or `HITL`

Use `needs-triage` only before scope is clear. Remove it when the issue has acceptance criteria and a verification plan.

`HITL` means a human credential, signing identity, clean Mac, visual judgement, or external account is required. Do not pretend AFK automation can finish HITL release work.

---

## PR maintenance checklist

Every PR should answer:

- Which issue does this close or advance?
- What user-visible behavior changed?
- Which safety invariant could be affected?
- What passed locally?
- What was not verified?
- Did `docs/IMPLEMENTATION_STATUS.md` need an update?
- Did `docs/DECISIONS.md` need an update?

Docs-only PRs do not need forced TDD, but they still need a review path: links checked, stale claims removed, source-of-truth relationship clear.

---

## Release readiness checklist

A release candidate is not ready until all of these are attached to a release PR or issue comment:

```bash
python3 -m unittest discover tests
xmllint --noout app/macos/FolderTrail.xcodeproj/xcshareddata/xcschemes/*.xcscheme
plutil -lint app/macos/FolderTrail/Info.plist app/macos/FolderTrail/FolderTrail.entitlements app/macos/FolderTrail.xcodeproj/project.pbxproj
xcodebuild -project app/macos/FolderTrail.xcodeproj -scheme FolderTrail -configuration Release build
spctl --assess --verbose path/to/FolderTrail.app
spctl --assess --verbose path/to/FolderTrail-0.1.dmg
```

Also attach human QA notes for:

- clean install on a non-dev Mac,
- Finder Services visibility,
- Codex login from the packaged app,
- one real folder run,
- resulting `trail.json` inspection,
- uninstall/rollback notes.

---

## Weekly or pre-release triage

Run this before any release push or when project state feels unclear:

```bash
gh issue list --state open --limit 100
gh pr list --state open --limit 100
python3 -m unittest discover tests
git status --short
```

Then update `docs/IMPLEMENTATION_STATUS.md` if the public story changed.

---

## Maintenance anti-patterns

Avoid:

- claiming “v0.1 done” while #14 or release QA remains open,
- letting old provider-neutral wording override Codex-first implementation,
- keeping decisions only in chat logs,
- adding broad “phase” issues that cannot be independently verified,
- closing HITL issues without the human evidence they require,
- treating unit tests as a substitute for Finder/package smoke tests.

