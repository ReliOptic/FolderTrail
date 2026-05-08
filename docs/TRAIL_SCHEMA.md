# Trail Schema

The trail is the evidence chain of every FolderTrail run.
Three files are written to `.foldertrail/` inside the workspace:

| File | Purpose |
|---|---|
| `summary.md` | Human-readable Korean summary |
| `trail.json` | Machine-readable full execution record |
| `runtime_status.json` | App-owned status state (written by FolderTrail, not AI) |

## `trail.json` Schema

```json
{
  "foldertrail_version": "0.1",
  "run_id": "ft_2026_05_08_001",
  "started_at": "2026-05-08T13:24:06Z",
  "completed_at": "2026-05-08T13:25:14Z",
  "interrupted": false,
  "source_folder": "/Users/you/Desktop/Conference_2026",
  "workspace_folder": "/Users/you/Desktop/Conference_2026_FolderTrail_Workspace",
  "user_prompt": "식순 기준으로 폴더를 정리해줘.",
  "provider": "openrouter",
  "model": "anthropic/claude-sonnet-4.6",
  "manifest_detail_level": "level_2_path_summary",
  "actions_executed": [
    {
      "type": "create_folder",
      "path": "01_Keynote",
      "status": "success"
    },
    {
      "type": "move",
      "from": "photos/IMG_1022.jpg",
      "to": "01_Keynote/photos/IMG_1022.jpg",
      "status": "success"
    }
  ],
  "rejected_actions": [],
  "validation_errors": [],
  "summary": {
    "folders_created": 8,
    "files_moved": 243,
    "files_renamed": 31,
    "review_needed": 6
  }
}
```

## `runtime_status.json` Schema

Written and owned by the FolderTrail app (not by AI providers).

```json
{
  "run_id": "ft_2026_05_08_001",
  "workspace": "Conference_2026_FolderTrail_Workspace",
  "source": "foldertrail_app",
  "current_status": "organizing",
  "steps": [
    { "key": "preflight", "state": "done", "detail": "권한 및 provider 확인 완료" },
    { "key": "copying_workspace", "state": "done", "detail": "복사본 생성 완료" },
    { "key": "scanning", "state": "done", "detail": "842개 항목 확인" },
    { "key": "planning", "state": "done", "detail": "action plan 수신" },
    { "key": "organizing", "state": "running", "detail": null },
    { "key": "writing_trail", "state": "waiting", "detail": null }
  ],
  "counters": {
    "files_seen": 842,
    "folders_created": null,
    "files_moved": null,
    "files_renamed": null,
    "review_needed": null
  }
}
```

Counters are `null` until `trail.json` is parsed at completion.

## Invariants

- `run_id` is unique per run: `ft_<YYYY>_<MM>_<DD>_<NNN>`
- `source_folder` is always read-only — never appears in `actions_executed` as a target
- `interrupted: true` is set when the user cancels mid-execution
- All paths in `actions_executed` are relative to `workspace_folder`
