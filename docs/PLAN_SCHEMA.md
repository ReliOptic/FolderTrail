# Plan Schema

The `ActionPlan` is the structured output returned by a Provider Adapter.
It is validated by `SafeExecutor` before any filesystem operation is performed.

## Allowed Action Types

| Type | Description | Safe Executor behavior |
|---|---|---|
| `create_folder` | Create a directory | `FileManager.createDirectory` |
| `move` | Move a file to a new path | `FileManager.moveItem` |
| `rename` | Rename a file in-place | `FileManager.moveItem` (same dir) |
| `copy` | Duplicate a file | `FileManager.copyItem` |
| `write_summary` | Write a text file | `String.write(to:)` |
| `mark_review_needed` | Flag a file for human review | Move to `_review_before_delete/` |

## Rejected Action Types

Any action not in the allowlist above is **silently rejected** and logged in `trail.json` under `rejected_actions`.

Explicitly forbidden:
- `delete`
- `shell_exec`
- `network_call`
- Any path referencing `..` or absolute paths outside workspace

## JSON Schema

```json
{
  "plan_version": "0.1",
  "provider": "openrouter",
  "model": "anthropic/claude-sonnet-4.6",
  "summary_ko": "식순 기준으로 8개 세션 폴더를 만들고 243개 파일을 분류했습니다.",
  "actions": [
    {
      "type": "create_folder",
      "path": "01_Keynote"
    },
    {
      "type": "move",
      "from": "photos/IMG_1022.jpg",
      "to": "01_Keynote/photos/IMG_1022.jpg"
    },
    {
      "type": "rename",
      "from": "notes.txt",
      "to": "keynote_notes.md"
    },
    {
      "type": "mark_review_needed",
      "path": "unknown_archive.zip",
      "reason": "Large archive file — content not inspected"
    }
  ]
}
```

## Validation Rules (Safe Executor)

Before executing any action, Safe Executor checks:

1. `type` is in the allowlist
2. All path values resolve **inside** the workspace root
3. No path component is `..`
4. `from` / `path` files actually exist in workspace
5. `to` / `path` destinations don't escape workspace root

Failed validations are recorded in `trail.json` under `validation_errors` and the action is skipped.
