# FolderTrail SLC PRD v0.1 — Final

## 0. 문서 목적

이 문서는 FolderTrail v0.1을 **Simple, Lovable, Complete(SLC)** 기준으로 개발하기 위한 최종 제품 기획안이다.

FolderTrail v0.1은 큰 플랫폼을 만들기 위한 문서가 아니다. 첫 릴리즈에서 반드시 닫혀야 하는 하나의 완결된 경험을 정의한다.

> 폴더 우클릭 → New FolderTrail → provider 연결 → 자연어 요청 → 안전 복사본 생성 → AI 폴더 작업 → Compact Status 확인 → Trail Summary 확인 → 결과 폴더 열기

---

## 1. Product Definition

### 1.1 One-liner

**FolderTrail은 선택한 폴더의 안전 복사본을 만들고, 그 안에서 AI provider가 계획을 세우고 FolderTrail이 실행한 뒤, 정리·구조화·실행 과정을 사람이 이해 가능한 Compact Status와 Trail Summary로 보여주는 folder-native AI UX다.**

### 1.2 English One-liner

**FolderTrail creates a safe copy of any folder, runs AI-planned organization inside it, and shows a compact trail of what changed.**

### 1.3 Product Identity

FolderTrail은 폴더를 AI 작업 공간으로 바꾸는 가장 자연스러운 인터페이스다.

사용자는 Finder에서 이미 폴더를 중심으로 일한다. FolderTrail은 이 익숙한 흐름 위에 얇은 AI 실행 레이어를 올린다.

```text
Right-click any folder.
Describe what you want.
Watch the compact trail.
Open the organized result.
```

---

## 2. Core Product Principles

### 2.1 v0.1 핵심 판단

1. **Provider-neutral, Safe Executor-first**
   모든 AI provider는 action plan을 제안한다. FolderTrail Safe Executor만 실제 파일을 변경한다.

2. **macOS-first**
   Finder 서비스 메뉴 기반 경험을 먼저 완성한다.

3. **Copy-workspace-first**
   원본 폴더를 직접 변경하지 않는다. 항상 안전 복사본에서 실행한다.

4. **Compact Status-first**
   터미널 로그를 그대로 보여주지 않는다. 실제 정리 중인 일을 요약된 상태 정보로 보여준다.

5. **Explicit Consent-first**
   AI 실행 전 사용자의 명시적 허용을 받는다.

6. **Trail-first**
   결과뿐 아니라 변경 과정과 요약을 남긴다.

### 2.2 핵심 안전 원칙

```text
Providers plan.
FolderTrail validates.
FolderTrail executes.
Trail records.
```

---

## 3. SLC Scope

### 3.1 SLC 재정의

FolderTrail v0.1의 SLC 기준은 "기술 레이어 최소화"가 아니라 **"사용자 흐름 완결성"**이다.

```text
기존 SLC 후보:
Codex CLI installed user → FolderTrail runner

최종 SLC:
FolderTrail installed user → Connect provider → Safe workspace → AI folder action → Compact Trail
```

따라서 v0.1에는 Provider Adapter 구조를 포함한다.

### 3.2 Simple

사용자는 하나만 기억하면 된다.

```text
Finder에서 폴더 우클릭 → 서비스 → New FolderTrail
```

복잡한 프로젝트 생성, 클라우드 워크스페이스 연결, 별도 IDE 진입 없이 시작한다.

### 3.3 Lovable

사용자는 터미널을 직접 다루지 않는다.

대신 다음을 본다.

- 선택된 폴더명
- 자연어 요청 입력창
- 작업 중인 단계 요약
- 변경 요약
- 결과 폴더 열기

UX의 감각은 다음과 같다.

> 조용하고, 빠르고, 안심되는 폴더 정리 경험

### 3.4 Complete

v0.1은 아래 흐름을 끝까지 닫는다.

```text
폴더 선택
→ provider 연결
→ 자연어 요청
→ 안전 복사본 생성
→ Adaptive Manifest 빌드
→ AI action plan 생성
→ Safe Executor 검증 및 실행
→ Compact Status 표시
→ Trail Summary 생성
→ 결과 폴더 열기
```

---

## 4. v0.1 Essential Features

### 4.1 포함 기능

| 기능 | 설명 |
|---|---|
| Finder Service Entry | 우클릭 서비스 메뉴에서 `New FolderTrail` 실행 (NSServicesProvider) |
| Folder Path Binding | 선택한 폴더 path를 앱으로 전달 (NSPasteboard) |
| Floating Prompt | 자연어 요청 입력용 작은 플로팅 창 |
| Provider Onboarding | OpenRouter OAuth PKCE 연결 또는 API Key 입력 |
| Preflight Check | 폴더 읽기/쓰기 가능 여부, provider 연결 상태 확인 |
| User Consent Modal | 안전 복사본 생성 및 AI 실행 동의 |
| Copy Workspace | 원본 폴더를 복사한 작업 폴더 생성 |
| Adaptive Manifest Builder | 파일 수 기반 detail level 자동 조정 |
| OpenRouter Planner Adapter | manifest + prompt → JSON action plan 생성 |
| Safe Executor | action plan 검증 후 FileManager로 실행 |
| Local Codex CLI Fallback | 고급 fallback runtime |
| Compact Status | 작업 내용을 요약 상태로 표시 (앱 소유 state machine) |
| Trail Summary | 변경 요약 표시 |
| Result Folder Open | 결과 폴더 열기 |
| Re-run Button | Done 화면에서 같은 폴더로 다시 실행 |
| Trail Files | `.foldertrail/summary.md`, `.foldertrail/trail.json`, `.foldertrail/runtime_status.json` 생성 |

### 4.2 제외 기능

| 제외 기능 | v0.1 제외 이유 |
|---|---|
| Codex SDK / Node.js helper | 로컬 workspace 바인딩 동작 미검증, v0.2 후보 |
| Windows Explorer | macOS 서비스 메뉴 경험 우선 완성 |
| 원본 폴더 직접 Apply | 신뢰 확보 전까지 제외 |
| Visual Diff Tree | v0.2 확장 기능 |
| Menu bar 상주 앱 | v0.2 후보 |
| Trail history browser | v0.2 후보 |
| Cloud Sync | local-first 정체성 유지 |
| Raw Terminal Log 기본 노출 | Compact Status UX 우선 |
| 일시 정지 (Pause) | 파일 조작 중간 중단은 partial state를 만들어 의미 없음 |
| Mac App Store 배포 | Sandbox가 로컬 CLI 실행 및 임의 파일 접근과 충돌 |

---

## 5. App Framework Decision

### 5.1 Framework

FolderTrail v0.1은 **Swift/SwiftUI native macOS app**으로 구현한다.

| 항목 | 결정 |
|---|---|
| App Framework | Swift / SwiftUI |
| Platform | macOS-first |
| UI | SwiftUI floating panel |
| Native bridge | AppKit 최소 사용 |
| Finder entry | NSServicesProvider |
| File operations | Swift FileManager |
| AI provider call | Swift URLSession + Codable |
| CLI fallback | Swift Process() |
| Trail parsing | Swift Codable JSON |
| Node.js / Electron / Tauri | v0.1 제외 |

### 5.2 이유

FolderTrail의 핵심 실행은 Finder-native 진입, macOS 권한 처리, 로컬 파일 접근, subprocess 실행이다. 이 네 가지가 Swift/SwiftUI native 구조와 가장 잘 맞는다.

Electron은 UI 생산성은 좋지만 Finder 통합, 권한 UX, 파일 접근에서 native wrapper가 결국 필요해진다. Tauri는 장기적으로 매력적이나 v0.1 SLC 기준에서는 레이어가 하나 더 많다.

---

## 6. Distribution Decision

### 6.1 배포 방식

FolderTrail v0.1은 **Mac App Store를 제외하고 Developer ID 서명 + notarized DMG 직접 배포**로 간다.

| 항목 | 결정 |
|---|---|
| 배포 형태 | DMG 우선, PKG 선택 |
| 서명 | Developer ID Application |
| Notarization | 필수 |
| Hardened Runtime | 활성화 |
| App Sandbox | **비활성화** |
| Mac App Store | v0.1 제외 |

### 6.2 이유

FolderTrail v0.1은 사용자 환경의 Codex CLI를 Swift `Process()`로 실행하고, 임의 위치의 폴더를 복사하는 동작이 핵심이다. Mac App Store의 App Sandbox는 이 구조와 충돌한다.

### 6.3 안전 경계

App Sandbox 대신 FolderTrail 자체 runtime boundary가 안전 모델이다.

```text
User-selected folder
→ Safe copied workspace
→ Explicit consent
→ Safe Executor: only allowed actions
→ No deletion, only _review_before_delete/
→ Trail summary
```

### 6.4 Codex CLI Path Resolution

FolderTrail은 Codex CLI를 번들하지 않는다. 사용자 로컬 설치본을 사용한다.

탐색 순서:
```text
1. User-configured Codex path (Settings)
2. /opt/homebrew/bin/codex
3. /usr/local/bin/codex
4. /usr/bin/env codex
5. /bin/zsh -lc "command -v codex"
```

---

## 7. Finder Entry — NSServicesProvider

### 7.1 구현 방식

Finder 우클릭 서비스 메뉴 진입은 **NSServicesProvider**로 구현한다.

앱 `Info.plist`에 `NSServices`를 선언하고, 런타임에 `NSApp.setServicesProvider()`로 핸들러를 등록한다. Automator Quick Action은 개발 중 fallback으로만 사용한다.

### 7.2 Info.plist 선언

```xml
<key>NSServices</key>
<array>
  <dict>
    <key>NSMenuItem</key>
    <dict>
      <key>default</key>
      <string>New FolderTrail</string>
    </dict>
    <key>NSMessage</key>
    <string>openFolderTrail</string>
    <key>NSPortName</key>
    <string>FolderTrail</string>
    <key>NSRequiredContext</key>
    <dict/>
    <key>NSSendFileTypes</key>
    <array>
      <string>public.folder</string>
    </array>
  </dict>
</array>
```

### 7.3 Service Provider 등록

```swift
@objc func openFolderTrail(
    _ pasteboard: NSPasteboard,
    userData: String?,
    error: AutoreleasingUnsafeMutablePointer<NSString?>
) {
    guard let urls = pasteboard.readObjects(
        forClasses: [NSURL.self], options: nil
    ) as? [URL],
    let folderURL = urls.first else { return }

    guard folderURL.hasDirectoryPath else {
        error?.pointee = "FolderTrail requires a folder selection." as NSString
        return
    }
    DispatchQueue.main.async {
        FolderTrailAppController.shared.openPrompt(for: folderURL)
    }
}
```

### 7.4 다중 폴더 선택

v0.1은 첫 번째 폴더만 처리한다. 파일 선택 시 안내 메시지를 표시한다.

---

## 8. Primary User Experience

### 8.1 Entry Flow

```text
1. 사용자가 Finder에서 폴더를 우클릭한다.
2. 서비스 메뉴에서 New FolderTrail을 선택한다.
3. FolderTrail 플로팅 창이 열린다.
4. provider가 연결되지 않은 경우 Connect Provider 화면을 먼저 보여준다.
5. 선택된 폴더명이 표시된다.
6. 사용자가 자연어로 요청한다.
7. FolderTrail이 접근 권한과 provider 상태를 확인한다.
8. 사용자에게 안전 복사본 생성 및 AI 실행 동의를 받는다.
9. 복사본 workspace를 만든다.
10. Adaptive Manifest를 빌드한다.
11. provider가 action plan을 생성한다.
12. Safe Executor가 검증 후 복사본 안에서 실행한다.
13. 사용자는 Compact Status로 진행 상황을 본다.
14. 작업 완료 후 Trail Summary를 확인한다.
15. 결과 폴더를 연다.
```

### 8.2 App Lifecycle

FolderTrail v0.1은 **one-shot floating panel**이다.

```text
Finder 우클릭
→ Floating Panel 열림
→ 요청 입력
→ 실행
→ Done 화면 유지
→ [결과 폴더 열기] / [이 폴더로 다시 실행] / [닫기]
→ 창 닫으면 앱 종료
```

메뉴바 상주, background daemon, 실행 이력 브라우저는 v0.2 후보다.

---

## 9. Provider Architecture

### 9.1 Provider Adapter Layer

FolderTrail Core는 provider-neutral이다.

```text
FolderTrail Core
 ├─ Workspace Copier
 ├─ Adaptive Manifest Builder
 ├─ Safe Executor
 ├─ Compact Status State Machine
 └─ Trail Writer

Provider Adapters
 ├─ OpenRouter Planner Adapter     ← Primary (v0.1)
 ├─ Local Codex CLI Adapter        ← Fallback (v0.1)
 └─ Codex SDK Adapter              ← Deferred (v0.2 검증 후)
```

### 9.2 Provider별 역할

| Provider | v0.1 역할 | 파일 변경 권한 | 안전 모델 |
|---|---|---|---|
| OpenRouter Planner | action plan 생성 | **없음** | Safe Executor 통과 |
| Local Codex CLI | fallback runtime | 있음 | Copied workspace + 동의 |
| Codex SDK | 검증 보류 | TBD | v0.2 결정 |

핵심 원칙:

```text
OpenRouter plans.
FolderTrail validates.
FolderTrail executes.
Codex CLI fallback runs only inside copied workspace.
```

### 9.3 Codex SDK 검증 항목

Codex SDK가 v0.2 Primary Adapter로 올라오려면 다음이 확인되어야 한다.

```text
1. SDK가 local workspace path를 명시적으로 바인딩할 수 있는가?
2. SDK가 로컬 파일을 읽고 쓸 수 있는가?
3. SDK가 filesystem mutation을 구조화된 event로 반환하는가?
4. SDK가 workspace 밖 접근을 차단할 수 있는가?
5. SDK가 Safe Executor와 결합 가능한 action plan 모드로 동작할 수 있는가?
```

---

## 10. OpenRouter Connection — OAuth PKCE

### 10.1 연결 방식

FolderTrail v0.1은 OpenRouter 연결을 **OAuth PKCE-first**로 구현한다.

```text
Primary:
Connect OpenRouter → Browser OAuth PKCE → API key exchange → macOS Keychain 저장

Fallback (고급 옵션):
OpenRouter API Key 직접 입력 → Verify → macOS Keychain 저장
```

### 10.2 OAuth PKCE Flow

```text
1. FolderTrail이 code_verifier 생성
2. SHA-256 기반 code_challenge 생성
3. FolderTrail이 OpenRouter /auth URL을 브라우저로 연다
   (callback: http://localhost:3000/openrouter/callback)
4. 사용자가 OpenRouter 로그인 및 앱 권한 승인
5. OpenRouter가 callback URL로 code를 전달
6. FolderTrail이 code + code_verifier로 API key exchange 수행
7. 발급된 API key를 macOS Keychain에 저장
   service: FolderTrail / account: openrouter.default
8. OpenRouter Planner Adapter가 해당 key로 요청 실행
```

### 10.3 UX States

```text
Not Connected → Connect OpenRouter → Waiting for Browser Login
→ Exchanging Code → Connected → Ready to Plan
```

### 10.4 Custom URL Scheme

`foldertrail://auth` custom scheme은 OpenRouter callback 정책 검증 후 v0.2 후보로 둔다. v0.1 기본 callback은 temporary localhost callback server다.

---

## 11. OpenRouter Planner Adapter

### 11.1 동작 방식

```text
1. Adaptive Manifest Builder가 workspace 파일 목록을 manifest로 변환
2. OpenRouter Planner Adapter가 manifest + user prompt를 provider에 전달
3. provider가 JSON action plan을 반환
4. FolderTrail Safe Executor가 action plan을 검증
5. 허용된 action만 workspace 안에서 실행
6. .foldertrail artifacts 생성
```

### 11.2 System Prompt (OpenRouter용)

```text
You are FolderTrail Planner. Your task is to generate a structured JSON action plan for organizing the given folder.

Rules:
- Do not include delete actions. Use mark_review_needed instead.
- Only reference files within the provided workspace manifest.
- Do not access parent directories or external paths.
- Do not read or expose credentials, private keys, or sensitive files.
- Return only valid JSON matching the action plan schema.
- Write summary in Korean unless the user prompt specifies another language.
```

### 11.3 Action Plan Schema

```json
{
  "actions": [
    { "type": "create_folder", "path": "01_Keynote" },
    { "type": "move", "from": "IMG_1022.jpg", "to": "03_Photos/IMG_1022.jpg" },
    { "type": "rename", "from": "note.txt", "to": "keynote_notes.md" },
    { "type": "mark_review_needed", "path": "unknown.zip", "reason": "Large archive" }
  ],
  "summary_ko": "식순 기준으로 8개 세션 폴더를 만들고 243개 파일을 분류했습니다."
}
```

### 11.4 Safe Executor — 허용/금지 Action

허용:
```text
create_folder / move / rename / copy / write_summary / mark_review_needed
```

금지:
```text
delete / shell_exec / absolute_path_outside_workspace
parent_directory_access / credential_access / network_call
```

Safe Executor는 모든 경로가 workspace 내부인지 검증한 후 FileManager로 실행한다.

---

## 12. Adaptive Manifest Builder

### 12.1 Adaptive 전략

파일 수와 폴더 복잡도에 따라 manifest detail level을 자동 조정한다.

| 파일 수 | Manifest 수준 | 동작 |
|---|---|---|
| 0–200 | Level 3 metadata + text preview | 확장자·크기·수정일·제한적 텍스트 preview |
| 201–1,000 | Level 2 path summary | relative path, extension, size bucket |
| 1,001–5,000 | Directory summary + sampled files | 디렉터리 요약 + 확장자별 샘플 |
| 5,000+ | User confirmation | 사용자 확인 후 진행 |

### 12.2 원칙

```text
Send structure first.
Send metadata second.
Send content only when small, textual, and useful.
Never send secrets.
```

### 12.3 Text Preview 제한

대상: `.md` `.txt` `.csv` `.json` `.yaml` `.yml` `.rtf`

제외: `.env` `.pem` `.key` `.p12` `credentials*` `secret*` `token*` `password*`

파일당 최대 1,000 characters / 전체 preview 예산 최대 20,000 characters

### 12.4 대용량 폴더 UX

5,000개 이상이면 바로 호출하지 않고 사용자에게 안내한다.

```text
이 폴더에는 파일이 많습니다.
총 7,842개 항목이 감지되었습니다.
FolderTrail은 폴더 구조와 샘플만 사용해 정리 계획을 만듭니다.
원본 폴더는 변경하지 않습니다.
[계속]
[취소]
```

### 12.5 Manifest Output Schema

```json
{
  "manifest_version": "0.1",
  "workspace_name": "Conference_2026_FolderTrail_Workspace",
  "total_files": 842,
  "total_directories": 36,
  "detail_level": "level_2_path_summary",
  "privacy_filter_applied": true,
  "files": [
    {
      "path": "photos/IMG_1022.jpg",
      "extension": "jpg",
      "size_bucket": "1MB-5MB",
      "modified_date_bucket": "recent"
    }
  ],
  "directory_summary": [
    { "path": "photos", "files": 520, "types": { "jpg": 510, "mov": 10 } }
  ],
  "review_excluded": [
    { "path": ".env", "reason": "sensitive_filename_pattern" }
  ]
}
```

---

## 13. Model Selection

### 13.1 기본 모델

FolderTrail v0.1 OpenRouter Planner의 기본 모델은 **`anthropic/claude-sonnet-4.6`**이다.

### 13.2 Model Selector UI

기본 사용자는 모델을 고르지 않는다. Settings > Providers > OpenRouter > Planner Model에서 변경한다.

```text
모델 선택
● claude-sonnet-4.6  (기본)
○ claude-haiku-4.5   ← 빠름/저렴
○ gpt-4o             ← OpenAI 선호 시
○ gemini-2.5-flash   ← 초고속
○ 직접 입력          ← any OpenRouter model ID
```

Weekly popular 목록은 자동으로 기본값을 바꾸지 않는다. Discovery 옵션으로만 제공한다.

---

## 14. Floating Prompt UX

### 14.1 Prompt Window Layout

```text
┌────────────────────────────────────┐
│ 📁 FolderTrail                ⌘K   │
├────────────────────────────────────┤
│ 선택된 폴더                         │
│ Conference_2026                    │
├────────────────────────────────────┤
│ 이 폴더를 어떻게 정리할까요?          │
│                                    │
│ [ 자연어 요청 입력 영역 ]             │
│                                    │
├────────────────────────────────────┤
│ 추천  정리  분류  세션별 그룹화        │
├────────────────────────────────────┤
│ [안전 복사본에서 실행 →]              │
└────────────────────────────────────┘
```

### 14.2 추천 Prompt Chip

```text
이 폴더의 파일을 주제별로 정리해줘.
행사 식순 기준으로 사진·자료·스크립트를 분류해줘.
문서, 이미지, 영상, 메모를 보기 쉽게 폴더로 나눠줘.
```

---

## 15. Permission & Consent UX

### 15.1 Preflight Check

| 체크 항목 | 성공 조건 | 실패 시 UX |
|---|---|---|
| Selected folder path | NSPasteboard에서 path 수신 | 폴더를 다시 선택해주세요 |
| Read access | 파일 목록 scan 가능 | 폴더 접근 권한이 필요합니다 |
| Workspace write access | sibling 복사본 생성 가능 | 이 위치에 복사본을 만들 수 없습니다 |
| Provider connected | OpenRouter key 유효 | Provider를 연결해주세요 |
| Codex CLI (fallback only) | `codex --version` 성공 | Codex CLI 설치가 필요합니다 |

Full Disk Access는 기본 요구사항이 아니다. 필요 시에만 안내한다.

### 15.2 Consent Modal

```text
안전 복사본에서 AI를 실행합니다.

FolderTrail은 선택한 폴더의 복사본을 만들고,
그 복사본 안에서 AI가 파일을 정리합니다.

원본 폴더는 변경하지 않습니다.

선택한 폴더:
Conference_2026

생성될 작업 폴더:
Conference_2026_FolderTrail_Workspace

[허용하고 시작]
[취소]
```

---

## 16. Copy Workspace Spec

### 16.1 기본 동작

원본: `/Users/you/Desktop/Conference_2026`

작업 복사본: `/Users/you/Desktop/Conference_2026_FolderTrail_Workspace`

### 16.2 중복 이름 처리

```text
Conference_2026_FolderTrail_Workspace
Conference_2026_FolderTrail_Workspace_2
Conference_2026_FolderTrail_Workspace_3
```

### 16.3 복사 제외 기본값

```text
.git/
node_modules/
.DS_Store
.Trash/
.foldertrail/
```

### 16.4 Deletion Rule

파일을 삭제하지 않는다. 삭제 후보는 `_review_before_delete/`로 이동한다.

---

## 17. Compact Status UX

### 17.1 Purpose

Compact Status는 **앱이 소유하는 deterministic status machine**이다. Codex stdout을 파싱하거나 provider가 실시간 상태를 push하는 방식이 아니다.

사용자에게 "현재 작업 성격"을 보여주는 activity narrative다. 정확한 진행률이 아니다.

```text
Swift status machine = source of truth
provider status event = optional hint (v0.2)
trail.json = final result truth
```

### 17.2 Status Machine

```text
idle → preflight → copying_workspace → scanning
→ codex_running
    → understanding → planning → organizing → writing_trail
→ done / needs_review / error
```

실제 이벤트 기반 상태: `preflight`, `copying_workspace`, `scanning`, `codex_running`, `done`, `needs_review`, `error`

staged activity 상태 (Codex 실행 중): `understanding`, `planning`, `organizing`, `writing_trail`

### 17.3 Layout

```text
작업 중: Conference_2026_FolderTrail_Workspace

✓ 파일을 살펴보는 중
  842개 항목 확인

◐ 자료의 의미를 파악하는 중
  사진·스크립트·발표자료 관계 분석

◐ 폴더 구조를 준비하는 중
  세션 기준 그룹 생성

○ 파일을 정리하는 중

○ 트레일을 작성하는 중

[작업 중단]
```

### 17.4 Status Keys

| Status Key | 사용자 표시 문구 | 내부 트리거 |
|---|---|---|
| `scanning` | 파일을 살펴보는 중 | 파일 목록 수집 시작 |
| `understanding` | 자료의 의미를 파악하는 중 | provider 호출 시작 |
| `planning` | 폴더 구조를 준비하는 중 | action plan 수신 |
| `organizing` | 파일을 정리하는 중 | Safe Executor 실행 |
| `writing_trail` | 트레일을 작성하는 중 | artifacts 생성 |
| `done` | 정리가 완료되었습니다 | trail.json 파싱 성공 |
| `needs_review` | 확인이 필요한 항목이 있습니다 | review_needed > 0 |
| `error` | 작업을 완료하지 못했습니다 | provider 실패, 권한 실패 |

### 17.5 퍼센트 표시 금지

```text
금지: 73% 완료
사용: 파일을 정리하는 중
```

### 17.6 취소 모델

"일시 정지"는 v0.1에 없다. 사용자 개입은 **[작업 중단]**으로 통일한다.

| 단계 | 동작 | 결과 상태 |
|---|---|---|
| OpenRouter API 호출 중 | URLSession cancel | 변경 없음, cancelled |
| Safe Executor 실행 중 | 현재 action 완료 후 중단 | partial result, needs_review |
| Local Codex CLI 실행 중 | SIGTERM → SIGKILL | partial state, needs_review |

Safe Executor는 action 하나를 완료한 뒤 stop flag를 확인한다. 중단 시 `trail.json`에 `interrupted`를 기록한다.

---

## 18. Trail Output Spec

### 18.1 `.foldertrail/summary.md`

```md
# FolderTrail Summary

요청:
식순 기준으로 폴더를 정리해줘.

결과:
- 새 폴더 8개 생성
- 파일 243개 이동
- 파일 31개 이름 변경
- 확인 필요 항목 6개

원본 폴더는 변경하지 않았습니다.

결과 폴더:
Conference_2026_FolderTrail_Workspace
```

### 18.2 `.foldertrail/trail.json`

```json
{
  "foldertrail_version": "0.1",
  "run_id": "ft_2026_05_08_001",
  "source_folder": "/Users/you/Desktop/Conference_2026",
  "workspace_folder": "/Users/you/Desktop/Conference_2026_FolderTrail_Workspace",
  "user_prompt": "식순 기준으로 폴더를 정리해줘.",
  "provider": "openrouter",
  "model": "anthropic/claude-sonnet-4.6",
  "manifest_detail_level": "level_2_path_summary",
  "interrupted": false,
  "actions": [
    { "type": "create_folder", "path": "01_Keynote" },
    { "type": "move", "from": "IMG_1022.jpg", "to": "02_Session/IMG_1022.jpg" },
    { "type": "rename", "from": "note.txt", "to": "keynote_notes.md" }
  ],
  "summary": {
    "created": 8,
    "moved": 243,
    "renamed": 31,
    "review_needed": 6
  }
}
```

### 18.3 `.foldertrail/runtime_status.json`

앱이 직접 생성한다. provider 파일에 의존하지 않는다. `source: "foldertrail_app"`, 완료 전 카운터는 `null`이다.

---

## 19. UI States

### 19.1 Ready

```text
FolderTrail

선택된 폴더: Conference_2026
이 폴더를 어떻게 정리할까요?

[식순 기준으로 자료를 세션별로 분류해줘.]
[안전 복사본에서 실행]
```

### 19.2 Permission Check

```text
접근 권한 확인 중
✓ 폴더 읽기 가능
✓ 복사본 생성 가능
✓ Provider 연결됨
○ 작업 폴더 준비 중
```

### 19.3 Running

```text
Conference_2026 정리 중
✓ 파일을 살펴보는 중
◐ 자료의 의미를 파악하는 중
◐ 폴더 구조를 준비하는 중
○ 파일을 정리하는 중
○ 트레일을 작성하는 중
[작업 중단]
```

### 19.4 Done

```text
정리가 완료되었습니다.
생성: 8개 폴더
이동: 243개 파일
이름 변경: 31개 파일
확인 필요: 6개 항목
[결과 폴더 열기]
[이 폴더로 다시 실행]
[요약 보기]
[닫기]
```

### 19.5 Interrupted

```text
작업이 중단되었습니다.
일부 변경이 결과 폴더에 반영되었을 수 있습니다.
원본 폴더는 변경하지 않았습니다.
[결과 폴더 열기]
[요약 보기]
[다시 실행]
```

### 19.6 Error

```text
작업을 완료하지 못했습니다.
가능한 원인:
- 폴더 접근 권한이 부족합니다.
- Provider 연결이 필요합니다.
- 복사본을 만들 수 없습니다.
[다시 확인]
[설정 열기]
[취소]
```

---

## 20. Technical Architecture

### 20.1 v0.1 Architecture

```text
Finder Service Menu (NSServicesProvider)
        ↓
Selected Folder Path (NSPasteboard)
        ↓
FolderTrail Floating Panel (SwiftUI)
        ↓
Preflight Checker
        ↓
Consent Modal
        ↓
Workspace Copier (FileManager)
        ↓
Adaptive Manifest Builder
        ↓
Provider Adapter
 ├─ OpenRouter Planner (URLSession)  ← Primary
 └─ Local Codex CLI (Process)        ← Fallback
        ↓
Safe Executor (FileManager + path validation)
        ↓
Trail Writer (Codable)
        ↓
Compact Status State Machine
        ↓
Done View
```

### 20.2 Core Modules

| Module | Responsibility |
|---|---|
| Finder Service | NSPasteboard에서 폴더 path 수신 |
| UI Shell | floating panel, 상태 화면, Done 화면 |
| Preflight Checker | 권한, provider 연결 확인 |
| Workspace Copier | 안전 복사본 생성 (FileManager) |
| Manifest Builder | Adaptive manifest JSON 생성 |
| OpenRouter Planner | URLSession → JSON action plan |
| Safe Executor | action plan 검증 + FileManager 실행 |
| Local CLI Adapter | Swift Process() fallback |
| Status State Machine | app-owned deterministic status |
| Trail Writer | summary.md, trail.json, runtime_status.json |
| Result Opener | 결과 폴더 열기 |

---

## 21. Repo Structure

```text
foldertrail/
├── app/
│   └── macos/
│       ├── FolderTrail.xcodeproj
│       └── FolderTrail/
│           ├── FolderTrailApp.swift
│           ├── AppDelegate.swift
│           ├── Views/
│           │   ├── PromptView.swift
│           │   ├── PreflightView.swift
│           │   ├── ConsentView.swift
│           │   ├── CompactStatusView.swift
│           │   ├── DoneView.swift
│           │   └── ProviderConnectView.swift
│           ├── Services/
│           │   ├── FolderTrailServiceProvider.swift
│           │   ├── PreflightService.swift
│           │   ├── WorkspaceCopyService.swift
│           │   ├── ManifestBuilder.swift
│           │   ├── OpenRouterPlannerAdapter.swift
│           │   ├── LocalCLIAdapter.swift
│           │   ├── SafeExecutor.swift
│           │   └── TrailWriter.swift
│           ├── Models/
│           │   ├── PreflightResult.swift
│           │   ├── FolderManifest.swift
│           │   ├── ActionPlan.swift
│           │   ├── CompactStatusState.swift
│           │   └── TrailSummary.swift
│           └── Resources/
│               └── Info.plist
├── docs/
│   ├── PRD.md
│   ├── SPEC.md
│   ├── ARCHITECTURE.md
│   └── CONTRIBUTING.md
├── examples/
│   └── conference-folder/
├── LICENSE          (Apache-2.0)
└── README.md
```

---

## 22. Spec Driven Development Plan

### Spec 01 — Finder Service Entry

```text
Build a native macOS app that registers as an NSServicesProvider.

Acceptance Criteria:
- Finder에서 폴더 우클릭 후 New FolderTrail 실행 가능
- 선택한 폴더 path가 앱에 표시됨
- 폴더가 아닌 파일 선택 시 안내 메시지 표시
- Automator workflow 불필요
```

### Spec 02 — Preflight Check

```text
Implement preflight checks.

Input: selected_folder_path

Check:
1. folder exists and is readable
2. sibling workspace can be created
3. provider connected (OpenRouter key valid)
4. Codex CLI exists (fallback only)

Output: preflight_result.json
```

### Spec 03 — Floating Prompt + Provider Connect

```text
Create the floating prompt window with:
- selected folder path
- text input
- recommended prompt chips
- Run in Safe Copy button

If provider not connected, show Connect OpenRouter screen first.
OAuth PKCE flow: browser open → localhost callback → key exchange → Keychain save.
```

### Spec 04 — Consent Modal

```text
Create consent modal.

Show:
- workspace name to be created
- original folder is not modified

Buttons: [허용하고 시작] / [취소]
```

### Spec 05 — Copy Workspace

```text
Implement safe workspace creation.

Rules:
- Sibling folder: <original>_FolderTrail_Workspace
- Duplicate: append _2, _3
- Exclude: .git, node_modules, .DS_Store, .Trash, .foldertrail
```

### Spec 06 — Adaptive Manifest Builder

```text
Build manifest JSON from workspace.

Rules:
- 0–200 files: Level 3 metadata
- 201–1,000: Level 2 path summary
- 1,001–5,000: directory summary + samples
- 5,000+: user confirmation required

Privacy filter: exclude .env, .pem, .key, credential* patterns
Text preview: max 1,000 chars/file, 20,000 chars total budget
```

### Spec 07 — OpenRouter Planner Adapter

```text
Implement OpenRouter Planner Adapter.

Input: manifest JSON + user prompt
Output: validated action plan JSON

Use URLSession. Default model: anthropic/claude-sonnet-4.6
Validate response schema before passing to Safe Executor.
```

### Spec 08 — Safe Executor

```text
Implement Safe Executor.

Rules:
- Allow: create_folder, move, rename, copy, write_summary, mark_review_needed
- Reject: delete, shell_exec, parent_dir_access, absolute_path_outside_workspace
- All paths must resolve inside workspace
- Check stop flag between each action
- On cancel: record interrupted=true in trail.json

Use Swift FileManager for all operations.
```

### Spec 09 — Compact Status State Machine

```text
Implement app-owned deterministic Compact Status.

States: idle, preflight, copying_workspace, scanning, codex_running,
        understanding, planning, organizing, writing_trail,
        done, needs_review, error

Rules:
- No percentage display
- No raw terminal log in default view
- Staged activity during provider execution
- Actual counters only after trail.json parsed
- Unknown counters = null before completion
- Show [작업 중단] button during execution
```

### Spec 10 — Done State

```text
Implement Done state.

Show:
- created folders count
- moved files count
- renamed files count
- review-needed count

Buttons:
- [결과 폴더 열기]
- [이 폴더로 다시 실행]
- [요약 보기]
- [닫기]
```

---

## 23. Acceptance Criteria

```text
사용자는 Finder 서비스 메뉴에서 New FolderTrail을 실행할 수 있다.
앱은 선택한 폴더 path를 NSPasteboard로 수신한다.
앱은 폴더 읽기/쓰기 가능 여부를 확인한다.
앱은 provider 연결 상태를 확인한다.
앱은 OpenRouter OAuth PKCE 흐름을 지원한다.
앱은 API key를 macOS Keychain에 저장한다.
앱은 사용자에게 안전 복사본 생성과 AI 실행 동의를 받는다.
앱은 원본 폴더를 변경하지 않는다.
앱은 Adaptive Manifest를 파일 수에 따라 자동 조정한다.
앱은 민감 파일을 manifest에서 필터링한다.
OpenRouter Planner는 action plan JSON을 반환한다.
Safe Executor는 허용된 action만 FileManager로 실행한다.
Safe Executor는 workspace 경계 밖 경로를 거부한다.
Compact Status는 앱 소유 state machine으로 동작한다.
Compact Status는 퍼센트나 raw log를 기본 화면에 노출하지 않는다.
작업 완료 후 summary.md, trail.json, runtime_status.json을 생성한다.
사용자는 결과 폴더를 버튼 하나로 열 수 있다.
사용자는 Done 화면에서 같은 폴더로 다시 실행할 수 있다.
앱은 작업 중단 시 trail.json에 interrupted=true를 기록한다.
앱은 Developer ID로 서명되고 Notarization을 통과한다.
```

---

## 24. Release Plan

### Week 1 — Foundation

- Finder Service Entry (NSServicesProvider)
- 선택 폴더 path 전달 (NSPasteboard)
- SwiftUI Floating Prompt
- Preflight Check

### Week 2 — Provider Connection

- OpenRouter OAuth PKCE 연결
- Keychain 저장
- Consent Modal
- Copy Workspace

### Week 3 — AI Execution

- Adaptive Manifest Builder
- OpenRouter Planner Adapter
- Safe Executor
- Trail Writer

### Week 4 — Compact UX + Polish

- Compact Status State Machine
- Done State + Re-run
- Error handling 전체
- Developer ID 서명 + Notarization
- README / CONTRIBUTING

---

## 25. Open Source

FolderTrail은 오픈소스 프로젝트다.

라이선스: **Apache-2.0** (Codex CLI Apache-2.0과 통일)

오픈소스 범위:
- FolderTrail 앱 코드 전체
- SwiftUI shell, NSServicesProvider
- Workspace Copier, Manifest Builder, Safe Executor
- OpenRouter Planner Adapter
- Local Codex CLI Fallback Adapter
- Trail Writer

오픈소스 외 범위:
- OpenAI/OpenRouter hosted model 서비스
- 사용자의 OAuth token / API key
- OpenRouter backend

---

## 26. Final Product Rule

> **FolderTrail = right-clicked folder → provider connect → AI prompt → safe copied workspace → adaptive manifest → action plan → Safe Executor → compact trail → organized result**

한국어:

> **FolderTrail은 폴더를 우클릭하고 자연어로 요청하면, 안전 복사본 안에서 AI가 계획하고 FolderTrail이 실행하며, 그 과정을 간결한 트레일로 보여주는 로컬 폴더 AI UX다.**
