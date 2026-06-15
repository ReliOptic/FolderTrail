# FolderTrail Implementation Status

_Last reviewed: 2026-06-15_

This document is the public implementation ledger for FolderTrail. It answers three questions:

1. What is already implemented?
2. What is only test-covered or locally true, but not release-proven?
3. What remains open on GitHub?

It should be updated whenever a PR changes user-visible behavior, safety behavior, packaging, or provider/auth flow.

---

## Current headline

FolderTrail v0.1 is **functionally implemented but not release-complete**.

- GitHub issues checked: **54 total / 53 closed / 1 open**.
- Only open v0.1 issue: [#14 Distribution — Developer ID + Notarization](https://github.com/ReliOptic/FolderTrail/issues/14).
- Local implementation surface: **32 Swift files** under `app/macos/FolderTrail`.
- Local regression surface: **51 Python behavior/contract test files** under `tests/`.

Interpretation: the core Finder → prompt → preflight → plan → safe execution → trail loop exists in code and tests, but the app is not yet proven as a signed/notarized public release.

---

## Status by milestone

| Milestone | Status | Evidence | Remaining gap |
| --- | --- | --- | --- |
| M1 — Finder entry | Implemented | Issues #1, #2, #3, #5 and follow-up entry/UI issues are closed; app/service files exist under `App/` and `Entry/`. | Needs real macOS Finder smoke per release candidate. |
| M2 — Provider/auth readiness | Implemented, docs drift exists | Codex-first readiness, terminal-less OAuth, settings-only OpenRouter, and bounded preflight issues are closed (#30, #34, #59, #62, #63, #67, #79, #81, #83, #86, #87). | Product docs must say **Codex-first**, not provider-neutral/OpenRouter-first. |
| M3 — Safe workspace | Implemented | Consent, workspace copy, manifest builder, cancellation, and workspace mode policy issues are closed (#7, #8, #9, #99, #101, #105). | Direct-source mode weakens the original “never mutate original” story and must stay explicitly labeled. |
| M4 — Planning/execution/status | Implemented | Planner adapters, run pipeline, SafeExecutor, progress/cancel, direct mode UX, and compact status issues are closed (#10, #11, #12, #69, #84, #85, #95, #103). | Needs end-to-end smoke with real folders and real Codex auth before release claims. |
| M5 — Trail/done/distribution | Partially complete | Trail Writer + Done State is closed (#13); done definition is documented (#88). | Distribution is still open: [#14](https://github.com/ReliOptic/FolderTrail/issues/14). Signing/notarization/Gatekeeper verification are HITL. |

---

## Implemented and test-covered

The following contracts are enforced by tests and should be treated as product invariants unless deliberately changed through a new issue/PR:

- Finder/service entry opens the FolderTrail app surface.
- Prompt, settings, preflight, consent, status, and done views exist as SwiftUI surfaces.
- Codex is the primary readiness gate; OpenRouter is optional/settings-only.
- Codex login runs in-app without opening Terminal command files.
- Preflight distinguishes Codex install from Codex login state.
- Preflight checks are bounded and avoid blocking `waitUntilExit` usage.
- Workspace copy uses FileManager/clonefile-style local operations, supports cancellation, and excludes unsafe/generated folders.
- Manifest builder adapts detail level by folder size and filters sensitive filenames.
- Planner output must decode into a non-empty action plan.
- SafeExecutor rejects delete actions, rejects paths outside the workspace boundary, and routes delete candidates to `_review_before_delete/`.
- Compact status and cancellation are modeled explicitly.
- TrailWriter owns trail artifacts and done-state output.
- Workspace mode policy centralizes copied-workspace vs direct-source labels and behavior.

See `docs/DECISIONS.md` for the detailed test-to-decision ledger.

---

## Not yet release-proven

These are not safe to claim as done in release notes until fresh evidence is attached to a PR or issue comment:

- Developer ID signed `.app` and `.dmg` on a clean Mac.
- Apple notarization and stapling.
- Gatekeeper verification with `spctl --assess --verbose` on a machine outside the dev environment.
- Finder Services visibility after install/logout/restart on a clean Mac.
- End-to-end run using real Codex auth from the packaged app.
- Manual inspection of a real trail after a non-trivial folder organization run.

---

## Known documentation drift

The repo has moved from the original OpenRouter-first/provider-neutral shape to a **Codex-first** operational model.

Docs that mention provider neutrality or OpenRouter as the main flow must be read against the newer implementation decisions in:

- `docs/DECISIONS.md`
- `docs/PHILOSOPHY.md`
- Issue #83: Codex should be the primary readiness gate
- Issue #86: Move OpenRouter out of the main start flow into Settings

Maintenance rule: when code contradicts old product docs, update the product docs or open a documentation issue in the same PR.

---

## GitHub source of truth

Use this priority order when judging project state:

1. Open GitHub issues and active PRs.
2. Current tests and source code on `main`.
3. `docs/IMPLEMENTATION_STATUS.md` for milestone-level truth.
4. `docs/DECISIONS.md` for invariant/decision truth.
5. `docs/ISSUE_MAP.md` for historical v0.1 dependency shape.
6. Older PRD wording only after checking the newer decision/status docs.

