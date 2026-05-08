# FolderTrail Architecture

## System Overview

```
Finder Service Menu (NSServicesProvider)
        ↓
Selected Folder Path (NSPasteboard)
        ↓
FolderTrail Floating Panel (SwiftUI)
        ↓
Preflight Checker
  ├─ Folder read/write check
  ├─ Provider connection check
  └─ Codex CLI check (fallback only)
        ↓
Consent Modal
        ↓
Workspace Copier (FileManager)
  └─ <folder>_FolderTrail_Workspace/
        ↓
Adaptive Manifest Builder
  ├─ Level 3: 0–200 files
  ├─ Level 2: 201–1,000 files
  ├─ Summary: 1,001–5,000 files
  └─ Confirm: 5,000+ files
        ↓
Provider Adapter
  ├─ OpenRouter Planner (URLSession)  ← Primary
  └─ Local Codex CLI (Process)        ← Fallback
        ↓
Safe Executor (FileManager)
  ├─ Path boundary validation
  ├─ Action allowlist enforcement
  └─ Stop-flag between actions
        ↓
Trail Writer
  ├─ .foldertrail/summary.md
  ├─ .foldertrail/trail.json
  └─ .foldertrail/runtime_status.json
        ↓
Done View
  ├─ Open result folder
  ├─ Re-run on same folder
  └─ Close
```

## Module Responsibilities

| Module | Layer | Responsibility |
|---|---|---|
| `FolderTrailServiceProvider` | Entry | NSPasteboard → folder URL |
| `PreflightService` | Safety | Read/write checks, provider status |
| `WorkspaceCopyService` | Safety | FileManager copy, dedup, exclusions |
| `ManifestBuilder` | Intelligence | Adaptive manifest JSON |
| `OpenRouterPlannerAdapter` | Intelligence | URLSession → action plan JSON |
| `LocalCLIAdapter` | Intelligence | Swift Process() → Codex CLI |
| `SafeExecutor` | Execution | Validate + FileManager execute |
| `TrailWriter` | Output | summary.md, trail.json |
| `CompactStatusStateMachine` | UX | App-owned deterministic status |

## Safety Invariants

1. Original folder path is read-only after workspace copy starts
2. Safe Executor only executes actions within workspace boundary
3. No `delete` actions — only `mark_review_needed` → `_review_before_delete/`
4. Stop flag is checked between every Safe Executor action
5. Interrupted runs record `interrupted: true` in trail.json

## Provider Model

```
Provider Adapters
├─ OpenRouter Planner (v0.1 Primary)
│   └─ Returns JSON action plan → Safe Executor
├─ Local Codex CLI Fallback (v0.1)
│   └─ Runs inside workspace, produces .foldertrail artifacts
└─ Codex SDK Adapter (v0.2 — pending local workspace verification)
```

## App Lifecycle

FolderTrail v0.1 is a **one-shot floating panel**.

```
Finder right-click → Panel opens → Run → Done view → Close
```

No menu bar icon. No background daemon. No persistent history (v0.2).
