# FolderTrail

**Finder 폴더 위에 얇게 올라가는, 안전한 AI 정리 레이어.**

FolderTrail은 새 작업 앱을 강요하지 않습니다. Finder에서 폴더를 우클릭하고 원하는 정리 방식을 말하면, FolderTrail이 작업 공간을 준비하고 AI 계획을 검증한 뒤 사람이 읽을 수 있는 trail을 남깁니다.

> 현재 상태: v0.1 핵심 기능은 구현되어 있고 테스트로 보호되어 있지만, **공개 릴리스는 아직 완료되지 않았습니다.** Developer ID 서명, Apple notarization, 깨끗한 Mac에서의 Gatekeeper 검증, 패키징된 앱 QA는 [#14](https://github.com/ReliOptic/FolderTrail/issues/14)에 남아 있습니다. 현재 구현률은 [Implementation Status](docs/IMPLEMENTATION_STATUS.md)를 기준으로 봅니다.

---

## 제품 입장

FolderTrail은 AI를 **증강(augmentation)** 이 아니라 **윤활(lubrication)** 로 봅니다.

새 능력을 준다고 과장하지 않습니다. 사람들이 이미 하던 일, 즉 폴더 정리의 마찰과 공포를 줄이는 것이 목표입니다.

그래서 제품은 아래 방향에 맞춰져 있습니다.

- **Finder-native entry** — chat 앱으로 이동하지 않고, 폴더에서 바로 시작합니다.
- **Reversibility first** — 기본값은 복사된 작업 공간입니다. 파일을 조용히 삭제하지 않습니다.
- **Legible output** — 무엇이 바뀌었고 무엇을 검토해야 하는지 trail로 남깁니다.
- **Low-friction AI** — Codex-first 로컬 CLI 흐름을 기본으로 두고, OpenRouter는 Settings의 선택 기능으로 둡니다.

더 긴 제품 철학과 긴장은 [Philosophy](docs/PHILOSOPHY.md)에 정리되어 있습니다.

---

## 사용 흐름

```text
Finder 폴더
→ 우클릭 “New FolderTrail”
→ 원하는 정리 방식을 자연어로 입력
→ preflight 체크 통과
→ 작업 공간 생성 또는 선택
→ AI가 action plan 작성
→ FolderTrail이 안전 검증 후 실행
→ 결과 폴더와 trail 확인
```

예시 요청:

> 식순 기준으로 사진·스크립트·발표자료를 세션별로 분류해줘.

예시 결과:

```text
생성: 8개 폴더
이동: 243개 파일
이름 변경: 31개 파일
확인 필요: 6개 항목

결과 폴더: Conference_2026_FolderTrail_Workspace
Trail: .foldertrail/trail.json
```

---

## 안전 모델

FolderTrail은 “AI가 내 파일을 망가뜨리면 어떡하지?”라는 공포를 중심으로 설계됩니다.

기본 흐름:

```text
원본 폴더
→ 복사된 작업 공간
→ AI는 계획만 작성
→ SafeExecutor가 모든 action 검증
→ 작업 공간 안에서만 이동/이름 변경 실행
→ 삭제 후보는 _review_before_delete/ 로 이동
→ trail.json에 실행 기록 저장
```

핵심 불변조건:

- 기본 copied-workspace 흐름에서는 원본 폴더를 변경하지 않습니다.
- 작업 공간 경계 밖 경로는 거부합니다.
- `delete` action은 거부합니다.
- 삭제 후보는 `_review_before_delete/`로 이동합니다.
- planner provider는 계획만 만들고, 파일 조작은 `SafeExecutor`가 맡습니다.
- trail artifact는 `TrailWriter`가 소유합니다.

코드에는 direct-source 모드도 있습니다. 이 모드는 명시적 고급 모드로 취급해야 하며, FolderTrail의 기본 안전 스토리는 copied-workspace입니다.

---

## 현재 구현 상태

2026-06-15 기준:

- GitHub issues: **54개 중 53개 closed, 1개 open**.
- 남은 open issue: [#14 Distribution — Developer ID + Notarization](https://github.com/ReliOptic/FolderTrail/issues/14).
- 로컬 구현: `app/macos/FolderTrail` 아래 **Swift 파일 32개**.
- 회귀 테스트: `tests/` 아래 **Python test file 51개**, 현재 **94 tests passing**.

| 영역 | 상태 |
| --- | --- |
| Finder entry / SwiftUI shell | 구현됨 |
| Prompt, settings, preflight, consent, status, done views | 구현됨 |
| Codex-first readiness와 terminal-less auth | 구현됨 |
| OpenRouter optional settings surface | 구현됨 |
| Workspace copy, manifest, planner, SafeExecutor | 구현됨 |
| Trail writer / done state | 구현됨 |
| Developer ID signing, notarization, clean-Mac release QA | **남음** |

현재 상태의 정본은 [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)입니다.

---

## Provider 모델

초기 문서에는 OpenRouter-first/provider-neutral 표현이 남아 있었지만, 현재 구현은 **Codex-first**입니다.

- Codex 인증은 메인 흐름의 required gate입니다.
- OpenRouter는 optional이며 Settings 안에만 있습니다.
- OpenRouter 미연결은 메인 시작 흐름을 막지 않아야 합니다.

현행 결정 정본은 [docs/DECISIONS.md](docs/DECISIONS.md)입니다. 오래된 PRD 문구는 [Implementation Status](docs/IMPLEMENTATION_STATUS.md)와 `DECISIONS.md`를 기준으로 다시 읽어야 합니다.

---

## Repository map

```text
app/macos/FolderTrail/
  App/            macOS 앱 lifecycle
  Entry/          Finder Services entry
  UX/             prompt, preflight, settings, status, done SwiftUI surfaces
  Safety/         preflight, readiness, credential boundaries
  Intelligence/   manifest builder and planner adapters
  Execution/      workspace copy, run pipeline, SafeExecutor, status machine
  Output/         trail writer

docs/
  IMPLEMENTATION_STATUS.md  현재 구현률 / 릴리스 상태
  MAINTENANCE.md            GitHub issue/PR/release 관리 규칙
  DECISIONS.md              테스트에서 역추출한 결정 ledger
  PHILOSOPHY.md             제품 철학과 긴장
  PRD.md                    제품 요구사항 맥락
  ISSUE_MAP.md              v0.1 historical dependency map

tests/
  Swift/macOS surface를 검증하는 Python behavior / contract tests
```

---

## 로컬 검증

자주 쓰는 체크:

```bash
python3 -m unittest discover tests
xmllint --noout app/macos/FolderTrail.xcodeproj/xcshareddata/xcschemes/*.xcscheme
plutil -lint app/macos/FolderTrail/Info.plist app/macos/FolderTrail/FolderTrail.entitlements app/macos/FolderTrail.xcodeproj/project.pbxproj
xcodebuild -project app/macos/FolderTrail.xcodeproj -scheme FolderTrail -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

릴리스 검증에는 사람의 signing/notarization credential과 깨끗한 Mac이 필요합니다. [Maintenance](docs/MAINTENANCE.md)와 [#14](https://github.com/ReliOptic/FolderTrail/issues/14)를 참고하세요.

---

## GitHub 관리 원칙

GitHub를 운영상의 source of truth로 둡니다.

- issue는 작업 범위와 릴리스 blocker를 정의합니다.
- PR은 검증 evidence를 남깁니다.
- `docs/IMPLEMENTATION_STATUS.md`는 현재 구현률과 릴리스 상태를 담습니다.
- `docs/DECISIONS.md`는 invariant와 결정의 정본입니다.
- `docs/MAINTENANCE.md`는 관리 규칙입니다.

PR이 구현률, 안전 동작, provider/auth 동작, 릴리스 준비도, 제품 철학을 바꾸면 같은 PR에서 관련 문서를 업데이트해야 합니다.

---

## 설치 / 릴리스 상태

현재 배포판은 릴리스 완료 상태가 아닙니다. 최종 사용자 설치 흐름은 다음 계약을 만족해야 합니다.

1. 릴리스 페이지에서 `FolderTrail-0.1.dmg`를 다운로드합니다.
2. DMG를 열고 `FolderTrail.app`을 `/Applications` 폴더로 이동합니다.
3. 첫 실행 후 Finder를 재실행하거나 로그아웃/로그인하면 Finder Services 메뉴에 `New FolderTrail`이 표시되어야 합니다.
4. Gatekeeper 경고 없이 열려야 합니다. 문제가 있으면 `spctl --assess --verbose` 결과를 이슈에 첨부합니다.

개발용 ad-hoc 빌드에서는 macOS Keychain이 저장된 OpenRouter 키 접근을 다시 허용하라고 요청할 수 있습니다. 최종 배포판은 Developer ID 서명과 notarization을 거친 뒤 깨끗한 Mac에서 이 동작을 다시 검증해야 합니다.

[#14](https://github.com/ReliOptic/FolderTrail/issues/14)가 아래 evidence와 함께 닫히기 전까지 public release complete로 보지 않습니다.

- Developer ID signed `.app` / `.dmg`
- Apple notarization and stapling
- clean Mac에서 Gatekeeper 검증
- 설치 후 Finder Services 노출 확인
- packaged app에서 Codex login 확인
- 실제 폴더 1회 실행과 trail inspection

개발 빌드는 로컬에서 동작할 수 있지만, notarized release와 같지 않습니다.

---

Apache-2.0 · macOS · Swift/SwiftUI · [ReliOptic/FolderTrail](https://github.com/ReliOptic/FolderTrail)
