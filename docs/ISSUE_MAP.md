# Issue Map — FolderTrail v0.1

> Historical dependency map for the original v0.1 slice. For current implementation completeness, release readiness, and live GitHub state, use [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md).

14 issues across 5 vertical milestones.

## Dependency Graph

```
#0 Repo Foundation
        ↓
#1 Bootstrap (Xcode + SwiftUI)
 ├─ #2 Finder Service Entry ──→ #3 Floating Prompt ──┐
 └─ #4 Provider Connect ──────→ #5 Preflight ────────┤
                                                      ↓
                                               #6 Consent Modal
                                                      ↓
                                               #7 Copy Workspace
                                                      ↓
                                               #8 Manifest Builder
                                                      ↓
                                          #4 + #8 → #9 Planner Adapter
                                                      ↓
                                          #7 + #9 → #10 Safe Executor
                                                      ↓
                                         #10 + #3 → #11 Status Machine
                                                      ↓
                                        #11 + #10 → #12 Trail Writer + Done
                                                      ↓
                                                 #13 Distribution
```

## Milestone Map

| Milestone | Goal | Issues | Done when |
|---|---|---|---|
| M1: Finder에서 앱이 열린다 | 진입점 확보 | #0 #1 #2 #3 | Finder 우클릭 → Floating Prompt 표시 |
| M2: 모델 연결 상태를 안다 | Provider 준비 | #4 #5 | OpenRouter 연결/미연결 판단 |
| M3: 원본을 보호하고 작업공간을 만든다 | 안전 실행 기반 | #6 #7 #8 | 동의 후 workspace + manifest 생성 |
| M4: 계획하고 안전하게 실행한다 | 핵심 가치 | #9 #10 #11 | action plan → 실행 → 상태 표시 |
| M5: 결과를 남기고 배포한다 | 제품 완결성 | #12 #13 | Trail + Done + notarized build |

## Issue List

| # | Title | Type | Blocks |
|---|---|---|---|
| 0 | Repo Foundation — scaffold, schemas, docs | AFK | #1 |
| 1 | Project Bootstrap — Xcode + SwiftUI shell | AFK | #2, #4 |
| 2 | Finder Service Entry — NSServicesProvider | AFK | #3 |
| 3 | Floating Prompt Window | AFK | #6 |
| 4 | Provider Connect — OpenRouter OAuth PKCE | AFK | #5, #9 |
| 5 | Preflight Check | AFK | #6 |
| 6 | Consent Modal | AFK | #7 |
| 7 | Copy Workspace | AFK | #8, #10 |
| 8 | Adaptive Manifest Builder | AFK | #9 |
| 9 | OpenRouter Planner Adapter | AFK | #10 |
| 10 | Safe Executor | AFK | #11, #12 |
| 11 | Compact Status State Machine | AFK | #12 |
| 12 | Trail Writer + Done State | AFK | #13 |
| 13 | Distribution — Developer ID + Notarization | HITL | — |
