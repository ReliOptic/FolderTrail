# FolderTrail

**폴더를 AI 작업 공간으로 바꾸는 가장 자연스러운 인터페이스.**

Finder에서 폴더를 우클릭하고, 원하는 것을 말하세요.  
FolderTrail이 안전한 복사본을 만들고, AI가 정리 계획을 세우고, 결과를 간결한 트레일로 보여줍니다.

---

## 어떻게 쓰나요?

```
폴더 우클릭
→ New FolderTrail
→ "식순 기준으로 사진·자료·스크립트를 분류해줘"
→ 안전 복사본 생성
→ AI 정리 실행
→ 결과 폴더 열기
```

원본 폴더는 건드리지 않습니다. 항상.

---

## 왜 FolderTrail인가?

대부분의 AI 도구는 새 앱을 배워야 합니다.  
FolderTrail은 이미 알고 있는 것 위에 올라갑니다 — **Finder**.

복잡한 설정 없이, 터미널 없이, 폴더를 우클릭하는 것만으로 시작합니다.  
정리가 끝나면 무엇이 어떻게 바뀌었는지 trail이 남습니다.

---

## 안전 모델

FolderTrail은 원본을 절대 바꾸지 않습니다.

```
원본 폴더
→ 안전 복사본 생성 (원본 유지)
→ AI가 복사본 안에서 계획 수립
→ FolderTrail이 검증 후 실행
→ 결과 + trail 기록
```

파일은 삭제하지 않습니다. 삭제 후보는 `_review_before_delete/` 폴더로 이동합니다.  
모든 실행은 `.foldertrail/trail.json`에 기록됩니다.

---

## 예시

**입력:**
> 식순 기준으로 사진·스크립트·발표자료를 세션별로 분류해줘.

**결과:**
```
생성: 8개 폴더
이동: 243개 파일
이름 변경: 31개 파일
확인 필요: 6개 항목

결과 폴더: Conference_2026_FolderTrail_Workspace
```

---

## v0.1 범위

- macOS Finder 우클릭 진입
- OpenRouter 기반 AI 폴더 정리
- 안전 복사본 + Safe Executor (원본 보호)
- Compact Status — 터미널 로그 없이 진행 상황 표시
- Trail 기록 — 무엇이 왜 바뀌었는지

---

## 문서

- [Contributing](CONTRIBUTING.md) — 기여 흐름과 TDD/PR 규칙
- [PRD](docs/PRD.md) — 제품 요구사항 전문
- [Architecture](docs/ARCHITECTURE.md) — 시스템 구조
- [Manifest Schema](docs/MANIFEST_SCHEMA.md) — 폴더 분석 계약
- [Plan Schema](docs/PLAN_SCHEMA.md) — AI 실행 계획 계약
- [Trail Schema](docs/TRAIL_SCHEMA.md) — 실행 결과 계약

---

Apache-2.0 · macOS · Swift/SwiftUI · [ReliOptic/FolderTrail](https://github.com/ReliOptic/FolderTrail)

---

## 설치 및 배포 상태

v0.1 배포 빌드는 Developer ID 서명과 Apple notarization을 전제로 합니다.

사용자 설치:

1. 릴리스 페이지에서 `FolderTrail-0.1.dmg`를 다운로드합니다.
2. DMG를 열고 `FolderTrail.app`을 Applications 폴더로 이동합니다.
3. 첫 실행 후 Finder를 다시 열거나 로그아웃/로그인하면 Finder Services 메뉴에 `New FolderTrail`이 표시됩니다.
4. Gatekeeper 경고 없이 열려야 합니다. 문제가 있으면 `spctl --assess --verbose` 결과를 이슈에 첨부해 주세요.

릴리스 빌드 담당자:

```bash
export TEAM_ID="YOUR_TEAM_ID"
export NOTARYTOOL_PROFILE="foldertrail-notary"
scripts/build.sh
```

Human checkpoints:

- Keychain에 `Developer ID Application` 인증서가 있는지 확인합니다.
- `app/macos/ExportOptions.plist`의 signing 설정과 Team ID를 검토합니다.
- notarization 후 stapled DMG를 빌드 머신이 아닌 깨끗한 Mac에서 Gatekeeper 검증합니다.
