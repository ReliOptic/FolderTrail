# FolderTrail

> Right-click a folder. Describe what you want. Get a safe organized copy with a compact trail.

FolderTrail is a macOS Finder-native AI folder organization assistant.

It never mutates the original folder directly. It creates a copied workspace, builds a manifest, generates an action plan via AI, safely executes approved file operations, and writes a trail log.

## Core Flow

```
Right-click folder in Finder
→ New FolderTrail
→ Connect provider (OpenRouter)
→ Describe what you want
→ Safe copy created
→ AI generates action plan
→ FolderTrail validates and executes
→ Compact trail shows what changed
→ Open organized result
```

## Safety Model

```
Providers plan.
FolderTrail validates.
FolderTrail executes.
Trail records.
```

- Original folder is **never modified**
- All work happens inside a copied workspace (`<folder>_FolderTrail_Workspace`)
- No files are deleted — review candidates move to `_review_before_delete/`
- Every run produces `.foldertrail/trail.json`, `.foldertrail/summary.md`

## v0.1 Stack

- **App**: Swift / SwiftUI native macOS
- **Finder entry**: NSServicesProvider
- **Primary provider**: OpenRouter Planner (URLSession)
- **Execution**: Safe Executor (FileManager)
- **CLI fallback**: Local Codex CLI (Swift Process)
- **Distribution**: Developer ID + Notarized DMG (non-sandboxed)
- **License**: Apache-2.0

## Documentation

- [PRD](docs/PRD.md) — Full product requirements
- [Architecture](docs/ARCHITECTURE.md) — System design
- [Issue Map](docs/ISSUE_MAP.md) — Development milestone map
- [Manifest Schema](docs/MANIFEST_SCHEMA.md) — Folder manifest contract
- [Plan Schema](docs/PLAN_SCHEMA.md) — AI action plan contract
- [Trail Schema](docs/TRAIL_SCHEMA.md) — Execution trail contract

## Status

🚧 Pre-alpha — v0.1 in development
