# Manifest Schema

The `FolderManifest` is the structured representation of a workspace's file contents.
It is built by `ManifestBuilder` and passed to the Provider Adapter for planning.

## Detail Levels

| Level | Name | Trigger | Contents |
|---|---|---|---|
| 3 | `metadata` | 0–200 files | path, extension, size, modified date, optional text preview |
| 2 | `path_summary` | 201–1,000 files | relative path, extension, size bucket |
| 1 | `directory_summary` | 1,001–5,000 files | directory tree + sampled files by type |
| 0 | `confirm` | 5,000+ files | User confirmation before any manifest build |

## JSON Schema

```json
{
  "manifest_version": "0.1",
  "workspace_name": "Conference_2026_FolderTrail_Workspace",
  "source_folder": "/Users/you/Desktop/Conference_2026",
  "total_files": 842,
  "total_directories": 36,
  "detail_level": "level_2_path_summary",
  "privacy_filter_applied": true,
  "files": [
    {
      "path": "photos/IMG_1022.jpg",
      "name": "IMG_1022.jpg",
      "extension": "jpg",
      "size_bytes": 3145728,
      "size_bucket": "1MB-5MB",
      "modified_date_bucket": "recent",
      "text_preview": null
    }
  ],
  "directory_summary": [
    {
      "path": "photos",
      "file_count": 520,
      "extension_breakdown": { "jpg": 510, "mov": 10 }
    }
  ],
  "review_excluded": [
    {
      "path": ".env",
      "reason": "sensitive_filename_pattern"
    }
  ]
}
```

## Privacy Filter

Files matching these patterns are excluded from the manifest and added to `review_excluded`:

**Excluded patterns:**
- `.env`, `.pem`, `.key`, `.p12`, `.mobileprovision`
- `credentials*`, `secret*`, `token*`, `password*`
- Hidden system files (`.DS_Store`, etc.)

**Text preview limits:**
- Eligible types: `.md`, `.txt`, `.csv`, `.json`, `.yaml`, `.yml`, `.rtf`
- Per-file max: 1,000 characters
- Total preview budget: 20,000 characters

## Invariants

- `privacy_filter_applied` must always be `true` before sending to any provider
- All `path` values are relative to `workspace_name` root
- `size_bytes` is omitted at Level 2 (use `size_bucket` only)
