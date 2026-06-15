# FolderTrail 결정 기록 (테스트에서 역추출) — 2026-06-15

> 이 문서는 `tests/test_issue_*.py` 및 `tests/test_*.py`에 박힌 설계 결정을 읽을 수 있게 역추출한 것이다.
> 테스트가 실제로 강제하는 사실은 그대로 기술하고, 이유가 코드/PRD 맥락에서만 추론되는 경우 반드시 **[추정]** 을 표기했다.

---

## 핵심 방향 결정

### Issue #83 — Codex-first provider readiness

- **결정**: Codex 인증이 required, OpenRouter 연결이 optional. Codex 미인증 시 `canProceed = false`로 메인 흐름 차단. OpenRouter 미연결만으로는 흐름이 차단되지 않는다.
- **강제 테스트**:
  - `tests/test_codex_first_readiness.py` — `test_issue_83_codex_auth_is_required_and_openrouter_is_optional`: `ProviderReadiness.evaluate(openRouterAPIKey: nil, codexAuthenticated: true).canProceed == true`이고 `evaluate(openRouterAPIKey: "sk-or-ready", codexAuthenticated: false).canProceed == false`임을 Swift smoke로 검증
  - `tests/test_codex_first_readiness.py` — `test_issue_83_preflight_blocks_on_codex_not_openrouter`: `PreflightCheck.swift`에 `providerConnected` 문자열 및 `OpenRouterCredentialStore.keychain.loadAPIKey` 부재 강제
  - `tests/test_codex_first_readiness.py` — `test_issue_83_prompt_start_button_is_not_hidden_by_openrouter_connection`: `PlaceholderPromptView.swift`에 `if providerSettings.isConnected` 부재 강제
  - `tests/test_provider_readiness.py` — `test_issue_83_readiness_logic_requires_codex_and_allows_optional_openrouter_to_fail`: OpenRouter 실패 메시지가 "설정" 포함, Codex 실패 메시지가 "Codex" 포함임을 검증
- **관련 코드**: `Safety/ProviderReadiness.swift`, `Safety/PreflightCheck.swift`, `UX/PlaceholderPromptView.swift`
- **[추정] 이유**: ChatGPT Plus 구독으로 Codex CLI를 API 비용 0으로 사용 가능한 반면 OpenRouter는 유료 API 키가 필요하다. 따라서 기본 진입 장벽을 Codex 인증으로만 두고 OpenRouter는 선택적 강화 옵션으로 설계한 것으로 보인다. 이번 "OpenRouter-first로 고치려다 되돌린" 사례가 이 결정을 직접 증명한다.

---

### Issue #86 — OpenRouter는 Settings 전용, 메인 흐름에서 완전 제거

- **결정**: OpenRouter 관련 UI(연결 버튼, 상태, API 키 입력)는 Settings 시트에만 존재한다. Prompt 메인 화면, Preflight 화면, Preflight 체크 로직 어디에도 OpenRouter가 노출되지 않는다.
- **강제 테스트**:
  - `tests/test_openrouter_settings_only.py` — `test_issue_86_prompt_keeps_openrouter_out_of_main_flow`: `PlaceholderPromptView.swift`의 메인 영역에 `CompactConnectionPanel`, `RequiredProviderRow`, `ProviderConnectView`, `Text("OpenRouter`, `Button("OpenRouter`, `providerConnected` 부재
  - `tests/test_openrouter_settings_only.py` — `test_issue_86_preflight_does_not_check_or_recover_openrouter`: `PreflightView.swift`에 `ProviderConnectView`, `providerSettings`, `OpenRouter` 부재; `PreflightCheck.swift`에 `providerConnected`, `OpenRouterCredentialStore.keychain.loadAPIKey`, `OpenRouter 연결됨` 부재
  - `tests/test_openrouter_settings_only.py` — `test_issue_86_openrouter_actions_remain_in_settings_only`: `FolderTrailApp.swift`와 `PromptSettingsSheet.swift`에 `ProviderConnectView`, `OpenRouterSettingsView` 존재
- **관련 코드**: `UX/PlaceholderPromptView.swift`, `UX/PreflightView.swift`, `Safety/PreflightCheck.swift`, `UX/ProviderConnectView.swift`, `UX/OpenRouterSettingsView.swift`, `App/FolderTrailApp.swift`
- **[추정] 이유**: 메인 흐름에 OpenRouter 연결 요구사항을 노출하면 "연결해야 쓸 수 있다"는 인상을 주어 Codex-first 의도와 충돌하고 UX 마찰이 증가한다. Settings로 격리해 "필요하면 연결"하는 구조로 유지.

---

### Issue #59 — Codex OAuth와 OpenRouter 연결은 별개의 분리된 인증 표면

- **결정**: Codex 로그인(`CodexChatGPTOAuthView`)과 OpenRouter 연결(`ProviderConnectView`)은 동일 컴포넌트를 공유하지 않는 별개 UI다. Settings 시트와 PreflightView 두 곳에서 동일한 `CodexChatGPTAuthView` 컴포넌트를 재사용한다.
- **강제 테스트**:
  - `tests/test_separate_auth_surfaces.py` — `test_issue_59_settings_shows_openrouter_and_codex_chatgpt_as_distinct_logins`: `PromptSettingsSheet.swift`에 `ProviderConnectionSection`, `CodexChatGPTOAuthView`, `AI 제공자`, `OpenRouter` 존재
  - `tests/test_separate_auth_surfaces.py` — `test_issue_59_codex_chatgpt_oauth_view_launches_visible_browser_handoff`: `CodexChatGPTAuthView.swift`에 `NSWorkspace.shared.open(url)` 부재
  - `tests/test_separate_auth_surfaces.py` — `test_issue_59_settings_and_preflight_reuse_same_codex_auth_surface`: `FolderTrailApp.swift`와 `PreflightView.swift` 모두에 `CodexChatGPTOAuthView` 존재; `PreflightView.swift`에 `private func openCodexLoginInTerminal` 부재
- **관련 코드**: `UX/CodexChatGPTAuthView.swift`, `UX/PromptSettingsSheet.swift`, `UX/PreflightView.swift`, `App/FolderTrailApp.swift`

---

### Issue #62 — Codex OAuth는 앱 내에서 실행, 터미널 열기 금지

- **결정**: `codex login` 실행은 앱이 직접 `Process()`로 실행한다. 터미널 앱을 별도로 열거나 `NSWorkspace.shared.open(commandURL)`, `extractAuthURL`, 사용자에게 터미널 명령 복사를 요구하는 방식 전부 금지.
- **강제 테스트**:
  - `tests/test_terminal_less_codex_oauth.py` — `test_issue_62_codex_oauth_runs_in_app_without_terminal_command`: `openInTerminal`, `.command`, `NSWorkspace.shared.open(commandURL)`, `Press return to close`, `터미널`, `extractAuthURL`, `NSWorkspace.shared.open(url)` 전부 부재; `Process()`, `readabilityHandler`, `브라우저에서 로그인하세요`, `로그인 후 자동 확인합니다` 존재
  - `tests/test_codex_oauth_single_browser_launch.py` — `test_issue_81_codex_login_delegates_browser_opening_to_cli_only`: `process.arguments = ["-lc", "codex login"]` 존재, `extractAuthURL` 부재
- **관련 코드**: `UX/CodexChatGPTAuthView.swift`
- **[추정] 이유**: 터미널이 열리면 사용자가 "개발자용 도구"를 쓴다는 느낌을 받는다. 앱 내 in-process 실행으로 CLI를 완전히 은닉.

---

### Issue #63 — 로그인 성공 시 자동 recheck 콜백

- **결정**: `CodexLoginRunner.start(onSuccess:)`가 성공 시 `onSuccess?()` 콜백을 호출하고, `PreflightView`는 이 콜백으로 `rerunPreflight`를 자동 실행한다. 사용자가 수동으로 재확인 버튼을 누를 필요 없이 로그인 성공 즉시 preflight가 다시 돌아간다.
- **강제 테스트**:
  - `tests/test_codex_login_auto_recheck.py` — `test_issue_63_successful_login_triggers_recheck_callback`: `loginRunner.start(onSuccess: onRecheck)`, `func start(onSuccess: (() -> Void)? = nil)`, `onSuccess?()` 존재
  - `tests/test_codex_login_auto_recheck.py` — `test_issue_63_preflight_passes_rerun_as_success_callback`: `CodexChatGPTOAuthView(onRecheck: rerunPreflight)`, `private func rerunPreflight`, `await runner.run(for: folderURL, workspaceMode: workspaceMode)` 존재
- **관련 코드**: `UX/CodexChatGPTAuthView.swift`, `UX/PreflightView.swift`

---

### Issue #79 — 기존 인증 상태를 브라우저 열기 전에 먼저 확인

- **결정**: `CodexLoginRunner`는 `runLoginProcess`를 호출하기 전에 `guard !(await Self.isAlreadyAuthenticated())`로 기존 인증 여부를 먼저 확인한다. 이미 인증된 상태이면 브라우저를 열지 않는다. 인증 완료 상태에서는 로그인 버튼이 비활성화된다.
- **강제 테스트**:
  - `tests/test_codex_oauth_completed_state.py` — `test_issue_79_existing_auth_is_checked_before_launching_browser_login`: `refreshExistingLoginStatus`, `guard !(await Self.isAlreadyAuthenticated())`, `PreflightCheck.isCodexAuthenticated()`, `.task { await loginRunner.refreshExistingLoginStatus() }` 존재; `isAlreadyAuthenticated` 확인이 `runLoginProcess` 호출보다 먼저 등장
  - `tests/test_codex_oauth_completed_state.py` — `test_issue_79_completed_auth_state_disables_repeat_login_and_explains_next_action`: `@Published private(set) var isAuthenticated = false`, `.disabled(loginRunner.isRunning || loginRunner.isAuthenticated)` 존재
- **관련 코드**: `UX/CodexChatGPTAuthView.swift`

---

### Issue #67 — recheck은 PreflightCheck의 bounded timeout 함수 재사용

- **결정**: 로그인 성공 후 상태 재확인은 `PreflightCheck.isCodexAuthenticated()`를 재사용한다. 이 함수는 `codexCommandTimeout: TimeInterval = 4` 제한을 갖는다. "로그인 완료. 확인 중…" 같은 합성 문구는 금지.
- **강제 테스트**:
  - `tests/test_codex_oauth_recheck_terminal_state.py` — `test_issue_67_recheck_reuses_bounded_preflight_status_check`: `PreflightCheck.isCodexAuthenticated()`, `static func isCodexAuthenticated() -> Bool`, `codexCommandTimeout: TimeInterval = 4` 존재; `로그인 완료. 확인 중…` 부재
- **관련 코드**: `UX/CodexChatGPTAuthView.swift`, `Safety/PreflightCheck.swift`

---

### Issue #34 — Codex 설치 실패와 Codex 로그인 실패는 별도 preflight 항목

- **결정**: `PreflightCheck`에 `case codexAvailable`(CLI 존재 여부)과 `case codexAuthenticated`(로그인 상태)가 분리된다. 각각의 실패 메시지도 다르다: 설치 실패 = `앱 환경에서 \`codex --version\`이 성공하지 않았습니다.`, 인증 실패 = `Codex 로그인 후 다시 확인해 주세요.`
- **강제 테스트**:
  - `tests/test_codex_oauth_status_preflight.py` — `test_issue_34_codex_auth_is_separate_from_cli_discovery`: `case codexAvailable`, `case codexAuthenticated`, `Codex 로그인됨`, `checkCodexAuthenticated`, `"login"`, `"status"`, `codex login status`, `runCodexLoginStatus` 존재
  - `tests/test_codex_oauth_status_preflight.py` — `test_issue_34_preflight_keeps_install_and_login_failures_distinct`: 설치 실패 메시지가 인증 실패 메시지보다 먼저 등장하는 순서 강제
- **관련 코드**: `Safety/PreflightCheck.swift`

---

### Issue #30 — GUI 앱 PATH 환경에서 codex 경로 탐색

- **결정**: macOS GUI 앱은 터미널의 `$PATH`를 상속받지 않으므로 Homebrew, pyenv, bun 등 일반적인 설치 경로를 하드코딩된 목록으로 탐색한다.
- **강제 테스트**:
  - `tests/test_codex_gui_path_preflight.py` — `test_issue_30_codex_lookup_handles_gui_path`: `/opt/homebrew/bin/codex`, `/usr/local/bin/codex`, `.local/bin/codex`, `.bun/bin/codex`, `/bin/zsh`, `command -v`, `codex --version`, `runCodexVersion` 존재
- **관련 코드**: `Safety/PreflightCheck.swift`

---

### Issue #52 — Preflight 체크는 bounded timeout + Task.detached, `waitUntilExit` 금지

- **결정**: Codex 관련 preflight 체크는 `Date().addingTimeInterval(timeout)`으로 시간을 제한하고 초과 시 `process.terminate()`한다. `process.waitUntilExit()` 호출은 금지(메인 스레드 블로킹 위험). UI는 먼저 pending 상태 행을 렌더링한 뒤 `Task.detached`로 백그라운드 체크를 실행한다.
- **강제 테스트**:
  - `tests/test_preflight_progress_timeout.py` — `test_issue_52_runner_renders_pending_rows_before_background_checks`: `static func pendingChecks`, `Task.detached(priority: .userInitiated)`, `let resolvedChecks = await Task.detached`, `checks = resolvedChecks` 존재
  - `tests/test_preflight_progress_timeout.py` — `test_issue_52_codex_checks_have_bounded_timeout_and_rerun_is_visible`: `codexCommandTimeout`, `timeout: TimeInterval = codexCommandTimeout`, `Date().addingTimeInterval(timeout)`, `process.terminate()` 존재; `process.waitUntilExit()` 부재
- **관련 코드**: `Safety/PreflightCheck.swift`, `UX/PreflightView.swift`

---

### Issue #38 / #6 — Preflight 4개 항목만 blocksProceed, OpenRouter 제외

- **결정**: `PreflightCheck`에서 `blocksProceed = true`인 항목은 `.folderReadable`, `.workspaceWritable`, `.codexAvailable`, `.codexAuthenticated` 4개뿐이다. `providerConnected`는 blocksProceed 항목에 없다.
- **강제 테스트**:
  - `tests/test_preflight_action_clarity.py` — `test_issue_38_codex_chatgpt_oauth_does_not_hide_primary_next_action`: `assertRegex(source, r"case \.folderReadable, \.workspaceWritable, \.codexAvailable, \.codexAuthenticated:\n\s+return true")`, `providerConnected` 부재; `checks.filter { $0.id.blocksProceed }` 존재; `PreflightView.swift`에 `OpenRouter` 부재
  - `tests/test_preflight_check.py` — `test_issue_6_preflight_contract`: `PreflightCheck.swift`에 `OpenRouterCredentialStore.keychain.loadAPIKey` 부재; `PreflightView.swift`에 `ProviderConnectView`, `OpenRouter` 부재
- **관련 코드**: `Safety/PreflightCheck.swift`, `UX/PreflightView.swift`

---

### Issue #37 — Keychain은 init에서 읽지 않고 명시적 refreshStatus 시에만 읽기

- **결정**: `OpenRouterProviderSettings`는 init 시점에 Keychain을 읽지 않는다(`hasCheckedStoredCredentials = false`). `refreshStatus(force: Bool = false)` 호출 시에만 읽으며, `OpenRouterKeychain.load` 직접 호출은 금지하고 `credentialStore.loadAPIKey`를 거친다.
- **강제 테스트**:
  - `tests/test_keychain_trust_guard.py` — `test_issue_37_provider_settings_do_not_read_keychain_on_init`: `private var hasCheckedStoredCredentials = false`, `case keychainPermissionNeeded`, `func refreshStatus(force: Bool = false)`, `guard force || !hasCheckedStoredCredentials else` 존재; `init() { refreshStatus() }` 패턴 부재; `OpenRouterKeychain.load` 직접 호출 부재
  - `tests/test_keychain_trust_guard.py` — `test_issue_37_provider_view_explains_keychain_before_user_action`: `저장된 연결 확인`, `저장된 키를 확인하거나 새로 연결하세요`, `Keychain 허용 필요`, `macOS 허용 후 다시 확인하세요`, `settings.refreshStatus()`, `settings.refreshStatus(force: true)` 존재
- **관련 코드**: `Intelligence/OpenRouterProviderSettings.swift`, `UX/ProviderConnectView.swift`
- **[추정] 이유**: macOS는 앱이 Keychain에 처음 접근할 때 권한 다이얼로그를 표시한다. init 시점에 읽으면 앱 시작마다 권한 프롬프트가 뜰 수 있다. 사용자가 Provider 설정을 명시적으로 열 때만 읽는 구조로 마찰 최소화.

---

### Issue #72 — Keychain 직접 읽기는 OpenRouterCredentialStore 뒤에 집중

- **결정**: `OpenRouterKeychain.load` 직접 호출은 `OpenRouterCredentialStore` 내부에서만 허용된다. `PreflightCheck`, `OpenRouterPlannerAdapter`, `OpenRouterProviderSettings` 어디서도 `OpenRouterKeychain.load`를 직접 호출하지 않는다. Store는 공백 키를 `nil`로 정규화한다.
- **강제 테스트**:
  - `tests/test_openrouter_credential_store.py` — `test_issue_72_direct_keychain_reads_are_concentrated_behind_store`: `preflight`, `planner`, `settings` 모두에서 `OpenRouterKeychain.load` 부재
  - `tests/test_openrouter_credential_store.py` — `test_issue_72_store_normalizes_blank_credentials_for_callers`: 공백 문자열 → `nil`, 앞뒤 공백 trim Swift smoke 검증
- **관련 코드**: `Safety/OpenRouterCredentialStore.swift`, `Safety/OpenRouterKeychain.swift`

---

### Issue #84 — Codex PlannerAdapter는 `codex exec` CLI를 사용

- **결정**: `CodexPlannerAdapter`는 `codex exec --output-last-message --sandbox read-only --ask-for-approval never --skip-git-repo-check` 플래그를 사용해 실행한다. JSON 응답을 `OpenRouterPlannerAdapter.decodeActionPlan`과 동일한 파서로 처리한다. 취소 시 `process.terminate()`를 호출하고 `CancellationError`를 throw한다.
- **강제 테스트**:
  - `tests/test_codex_planner_adapter.py` — `test_issue_84_codex_adapter_is_project_source_and_uses_codex_exec`: `codex exec`, `--output-last-message`, `--sandbox read-only`, `--ask-for-approval never`, `--skip-git-repo-check`, `CommandRunner` 존재
  - `tests/test_run_progress_cancel.py` — `test_issue_95_codex_cli_terminates_on_task_cancellation`: `Task.isCancelled`, `process.terminate()`, `CancellationError` 존재
- **관련 코드**: `Intelligence/CodexPlannerAdapter.swift`

---

### Issue #105 — WorkspaceModePolicy가 모드 관련 모든 문자열/동작의 단일 소유자

- **결정**: `WorkspacePreparationMode` enum은 `WorkspaceModePolicy.swift` 한 파일에만 존재한다. `modePickerTitle`, `modeDescription`, `preflightWorkspaceTitle`, `consentHeadline`, `consentDescription`, `workspaceReadyStepText`, `requiresPreflightBeforeConsent`, `primaryActionTitle` 등 모드 관련 모든 문자열과 동작 플래그를 이 enum의 computed property로 제공한다. 기본 모드 순서는 `[.copiedWorkspace, .directSource]` (안전 복사 우선).
- **강제 테스트**:
  - `tests/test_workspace_mode_policy_architecture.py` — `test_issue_105_workspace_mode_policy_is_the_single_public_mode_interface`: Pipeline, PreflightCheck, PreflightView 어디에도 `enum WorkspacePreparationMode`, `enum PreflightWorkspaceMode`, `preflightWorkspaceMode` 부재; 모든 소비처가 policy의 computed property를 참조
  - `tests/test_workspace_mode_policy_architecture.py` — `test_issue_105_workspace_mode_policy_behavior_is_stable`: smoke로 `copiedWorkspace.primaryActionTitle == "복사본으로 시작"`, `directSource.primaryActionTitle == "원본에서 바로 시작"`, `copiedWorkspace.requiresPreflightBeforeConsent == true`, `directSource.requiresPreflightBeforeConsent == false` 검증
- **관련 코드**: `Execution/WorkspaceModePolicy.swift`

---

### Issue #101 / #103 — Direct Source 모드 지원, pipeline은 모드에 따라 복사 건너뜀

- **결정**: `directSource` 모드에서 pipeline은 `copyWorkspace`를 호출하지 않고 원본 폴더를 workspace로 사용한다. UI에 `Picker("실행 방식", selection: $workspaceMode)` 모드 선택기를 제공한다. 오류 메시지는 플래너 에러 타입별로 한국어 액션 가이드를 제공한다.
- **강제 테스트**:
  - `tests/test_direct_run_mode.py` — `test_issue_101_pipeline_skips_copy_in_direct_mode`: `.directSource` 모드에서 `copyCalls == 0` 검증
  - `tests/test_direct_mode_ux_recovery.py` — `test_issue_103_run_model_surfaces_actionable_planner_failures`: `Codex 로그인이 필요합니다`, `Codex 실행에 실패했습니다`, `AI 응답을 실행 계획으로 읽지 못했습니다`, `실행 계획 형식이 맞지 않습니다` 존재
- **관련 코드**: `Execution/FolderTrailRunPipeline.swift`, `Execution/FolderTrailPromptRunModel.swift`, `Execution/WorkspaceModePolicy.swift`

---

### Issue #11 — SafeExecutor는 delete를 reject하고 workspace 경계를 강제

- **결정**: SafeExecutor는 `delete` action을 항상 reject한다. `../` 등 workspace 밖 경로는 `validation_errors`에 기록된다. `mark_review_needed` 파일은 `_review_before_delete/`로 이동한다. SafeExecutor는 자체적으로 `trail.json`이나 `.foldertrail` 디렉터리를 생성하지 않는다(TrailWriter 담당).
- **강제 테스트**:
  - `tests/test_safe_executor.py` — `test_issue_11_safe_executor_behavior`: `delete` reject, `../Escape` validation error, `_review_before_delete/` 이동, `trail.json` 미생성, `.foldertrail` 미생성 smoke 검증
- **관련 코드**: `Execution/SafeExecutor.swift`

---

### Issue #99 — WorkspaceCopyService는 clonefile 지원 및 취소 시 부분 복사본 삭제

- **결정**: 복사는 `clonefile`(macOS CoW) 우선, fallback으로 `copyFile`을 사용한다. 취소 발생 시 `CancellationError`를 throw하고 부분 생성된 workspace를 삭제한다.
- **강제 테스트**:
  - `tests/test_workspace_copy_fast_cancel.py` — `test_issue_99_workspace_copy_has_cancellation_and_fast_clone_contract`: `shouldCancel`, `Task.isCancelled`, `CancellationError`, `clonefile`, `copyFile` 존재
  - `tests/test_workspace_copy_fast_cancel.py` — `test_issue_99_cancellation_removes_partial_workspace`: 취소 후 `expectedWorkspace`가 존재하지 않음 smoke 검증
- **관련 코드**: `Execution/WorkspaceCopyService.swift`

---

### Issue #8 — WorkspaceCopyService는 Process() 금지, FileManager만 사용

- **결정**: `WorkspaceCopyService.swift`에 `Process()` 호출이 없어야 한다. 모든 복사 조작은 `FileManager`로만 수행한다. `.git`, `node_modules`, `.DS_Store`, `.Trash`, `.foldertrail` 디렉터리는 복사에서 제외한다. 중복 workspace 이름에는 `_2`, `_3` 접미사를 붙인다.
- **강제 테스트**:
  - `tests/test_workspace_copy_service.py` — `test_issue_8_safe_workspace_copy_behavior`: `Process()` 부재; 제외 항목 및 `_2` suffix smoke 검증
- **관련 코드**: `Execution/WorkspaceCopyService.swift`

---

### Issue #9 — ManifestBuilder는 파일 수 기반 detail level 자동 조정, 민감 파일 필터

- **결정**: 0–200개 = level_3_metadata, 201–1000개 = level_2_path_summary, 1001–5000개 = level_1_directory_summary, 5000+ = level_0_confirm(사용자 확인 필요). 텍스트 preview는 파일당 1,000자, 전체 20,000자 예산. `.env` 등 민감 파일은 `review_excluded`에 `sensitive_filename_pattern` 이유로 기록. 모든 경로는 절대경로가 아닌 상대경로.
- **강제 테스트**:
  - `tests/test_manifest_builder.py` — `test_issue_9_manifest_builder_behavior`: smoke로 level 경계값, privacy_filter_applied, 절대경로 미포함, preview 1000자 cap, .env 제외, 201개 파일 level_2 전환 검증
- **관련 코드**: `Intelligence/ManifestBuilder.swift`

---

### Issue #10 — OpenRouter PlannerAdapter는 빈 actions를 schemaMismatch로 처리

- **결정**: `OpenRouterPlannerAdapter.decodeActionPlan`은 `actions`가 비어있으면 `PlannerAdapterError.schemaMismatch`를 throw한다. 기본 모델은 `anthropic/claude-sonnet-4.6`이며 최소 2개의 `anthropic/` 모델을 목록에 포함한다.
- **강제 테스트**:
  - `tests/test_openrouter_planner_adapter.py` — `test_issue_10_planner_adapter_contract_and_parsing`: 빈 actions → `schemaMismatch` smoke 검증; `anthropic/claude-sonnet-4.6` 존재, `anthropic/` 등장 횟수 ≥ 2
- **관련 코드**: `Intelligence/OpenRouterPlannerAdapter.swift`

---

### Issue #12 — CompactStatus는 앱 소유 결정적 상태 머신, % 표시 금지

- **결정**: `CompactStatusStateMachine`은 `minimumStagedDuration = 10초`로 staged activity 상태를 진행한다. 실행 시간이 짧으면 staged 상태를 건너뛰고 직접 `done`으로 전환한다. counters는 완료 시에만 나타난다. `%` 문자와 `rawProvider` 노출은 UI에서 금지.
- **강제 테스트**:
  - `tests/test_compact_status_state_machine.py` — `test_issue_12_status_state_machine`: `minimumStagedDuration`, `10` 존재; 빠른 실행(`elapsed: 3`) → `done` 직행 smoke; `%`, `rawProvider` UI 부재
- **관련 코드**: `Execution/CompactStatusStateMachine.swift`, `UX/CompactStatusView.swift`

---

### Issue #13 — TrailWriter는 .foldertrail/ 서브디렉터리에 모든 아티팩트 저장

- **결정**: `trail.json`, `summary.md`, `runtime_status.json`은 workspace 루트가 아닌 `.foldertrail/` 서브디렉터리에 저장된다. 중단 시 `interrupted: true`와 `rejected_actions`, `validation_errors`를 trail에 기록한다. `runtime_status.json`의 `current_status`는 중단 시 `"interrupted"`이다.
- **강제 테스트**:
  - `tests/test_trail_writer_done_state.py` — `test_issue_13_trail_writer_done_state`: workspace 루트에 `trail.json` 미생성 smoke; `.foldertrail/` 내 아티팩트 존재; `interrupted: true` 직렬화 검증
- **관련 코드**: `Output/TrailWriter.swift`

---

### Issue #29 — OAuth 라운드트립 후 패널 재오픈 지원

- **결정**: `FolderTrailAppController`는 `NSWindowDelegate`를 구현하고 `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`로 패널을 유지한다. `windowWillClose`에서 `NSApp.terminate`를 호출한다. OAuth 완료 후 `bringPromptToFront`/`NSApp.activate`로 포커스를 복원한다.
- **강제 테스트**:
  - `tests/test_floating_panel_lifecycle.py` — `test_issue_29_panel_reopens_and_survives_oauth_roundtrip`
- **관련 코드**: `App/AppDelegate.swift`, `App/FolderTrailAppController.swift`, `UX/ProviderConnectView.swift`

---

### Issue #31 — 서비스 프로바이더 등록 후 NSUpdateDynamicServices() 호출 필수

- **결정**: `NSApp.setServicesProvider(serviceProvider)` 호출 직후 `NSUpdateDynamicServices()`를 호출해야 Finder 서비스 메뉴가 즉시 갱신된다. 순서 역전 금지.
- **강제 테스트**:
  - `tests/test_finder_services_refresh.py` — `test_issue_31_app_requests_services_refresh_at_launch`: index 비교로 순서 강제
- **관련 코드**: `App/AppDelegate.swift`

---

### Issue #2 / #3 — Finder 서비스는 NSServices 단일 항목, 첫 번째 폴더만 처리

- **결정**: `Info.plist`의 `NSServices`에 정확히 1개 항목이 있어야 한다(`New FolderTrail`, `openFolderTrail`, `public.folder`, `public.file-url`). 다중 폴더 선택 시 첫 번째 존재하는 폴더만 처리하고 파일이면 건너뛴다.
- **강제 테스트**:
  - `tests/test_finder_service_entry.py` — `test_issue_3_nsservices_contract_targets_finder_folder_urls`: `len(services) == 1` 강제
  - `tests/test_finder_service_entry.py` — `test_issue_3_folder_selection_uses_first_existing_folder_only`: `FolderTrailServiceSelection.firstExistingFolderURL` smoke 검증
- **관련 코드**: `Info.plist`, `Entry/FolderTrailServiceProvider.swift`

---

### Issue #14 — App Sandbox 비활성화, Hardened Runtime 활성화, Developer ID 서명

- **결정**: `FolderTrail.entitlements`에 `com.apple.security.app-sandbox = false`. `ENABLE_HARDENED_RUNTIME = YES`. 배포는 Developer ID + notarized DMG.
- **강제 테스트**:
  - `tests/test_project_bootstrap.py` — `test_issue_2_project_shell_contract`: `app-sandbox false`, `ENABLE_HARDENED_RUNTIME = YES` 강제
  - `tests/test_distribution_notarization.py` — `test_issue_14_distribution_contract`: `notarytool submit`, `stapler staple`, `Developer ID Application`, `ENABLE_HARDENED_RUNTIME = YES` 강제
- **관련 코드**: `FolderTrail.entitlements`, `FolderTrail.xcodeproj/project.pbxproj`, `scripts/build.sh`
- **[추정] 이유**: `Process()`로 로컬 Codex CLI를 실행하고 임의 경로 폴더를 복사해야 하므로 App Sandbox와 구조적으로 충돌한다.

---

### Issue #88 — "Done"은 사용자 가시적 인수 증거가 있을 때만

- **결정**: CONTRIBUTING.md와 AGENTS.md는 "테스트 통과" 또는 "브랜치 머지"만으로는 Done 선언을 금지한다. "acceptance evidence"(수동 또는 스크립트 smoke 확인, RED/GREEN 증거, known gaps 기록)가 있어야 Done이다.
- **강제 테스트**:
  - `tests/test_done_contract_docs.py` — `test_issue_88_contributing_defines_done_as_user_visible_acceptance`: CONTRIBUTING.md에 해당 문구들 존재
- **관련 코드**: `CONTRIBUTING.md`, `AGENTS.md`

---

### Issue #73 — 아키텍처 테스트는 Swift 소스 파싱이 아닌 behavior smoke로 작성

- **결정**: `test_provider_readiness.py`, `test_run_pipeline.py` 등 핵심 아키텍처 테스트는 Swift 소스 텍스트를 파싱하는 것이 아니라 실제 `swiftc`로 컴파일하고 실행해 동작을 검증하는 smoke 방식으로 작성한다. 테스트 파일에 `struct ProviderReadiness`나 `final class FolderTrailRunPipeline` 같은 구현 내용이 직접 들어가면 안 된다.
- **강제 테스트**:
  - `tests/test_architecture_test_behavior_contract.py` — `test_issue_73_hardened_architecture_tests_use_behavior_smoke_paths`

---

## PRD 동기화 필요 지점

PRD = `docs/PRD.md` (FolderTrail SLC PRD v0.1)

### 모순 1 (중요) — §10 "OpenRouter PKCE-first" 서술이 실제 Codex-first 의도와 충돌

**PRD §10.1**: "FolderTrail v0.1은 OpenRouter 연결을 **OAuth PKCE-first**로 구현한다."

**실제 결정(Issue #83)**: Codex 인증이 required, OpenRouter는 optional. Preflight 차단 요인은 Codex 미인증이고 OpenRouter 미연결은 차단하지 않는다.

**정정 방향**: §10 제목을 "OpenRouter Connection (Optional Enhancement)"으로 변경. "PKCE-first" 서술을 "Codex-first, OpenRouter optional enhancement"로 수정. §15.1 Preflight 체크 표에서 `Provider connected | OpenRouter key 유효 | Provider를 연결해주세요` 행을 "optional" 표시로 변경하거나 blocksProceed에서 제외한다는 주석 추가.

---

### 모순 2 — §8.1 Entry Flow 4번 "provider가 연결되지 않은 경우 Connect Provider 화면"

**PRD §8.1**: "4. provider가 연결되지 않은 경우 Connect Provider 화면을 먼저 보여준다."

**실제 결정(Issue #86)**: OpenRouter 미연결은 메인 흐름을 차단하지 않는다. Connect Provider 화면은 Settings 시트 안에서만 노출된다.

**정정 방향**: 4번 항목을 삭제하거나 "Codex 미인증인 경우 Preflight에서 안내"로 교체.

---

### 모순 3 — §15.1 Preflight 체크 표에 "Provider connected" 항목

**PRD §15.1**: `| Provider connected | OpenRouter key 유효 | Provider를 연결해주세요 |`

**실제 결정(Issue #38, #83, #86)**: PreflightCheck에 `providerConnected` 항목이 없다. blocksProceed 항목은 4개(`folderReadable`, `workspaceWritable`, `codexAvailable`, `codexAuthenticated`)뿐이다.

**정정 방향**: 해당 행 삭제. 대신 `| Codex CLI 설치 | codex --version 성공 | Codex 설치 안내 |`, `| Codex 인증 | codex login status 성공 | Codex 로그인 안내 |` 2행으로 교체.

---

### 모순 4 — §4.1 "Local Codex CLI Fallback" 표현과 §9.1 Provider Adapter 계층

**PRD §4.1 기능표**: `| Local Codex CLI Fallback | 고급 fallback runtime |`
**PRD §9.1**: `| Local Codex CLI Adapter ← Fallback (v0.1) |`

**실제 결정(Issue #84)**: `CodexPlannerAdapter`는 `codex exec` 모드로 동작하는 일급 PlannerAdapter이며 테스트에서 `CodexPlannerAdapter.swift`를 직접 `swiftc` 컴파일 대상으로 포함한다. "fallback"으로만 취급하기엔 구현이 완전하다.

**정정 방향**: §9 Provider 계층 표에서 "Fallback"을 "Secondary (CLI-based)" 또는 "Primary for Codex users"로 명확화. Codex-first 의도(Issue #83)와 일치시킬 것.

---

### 모순 5 — §20.1 아키텍처 다이어그램에 WorkspaceModePolicy 미등장

**PRD §20.1**: 아키텍처 다이어그램에 `Workspace Copier`, `Manifest Builder`, `Safe Executor` 등이 나오지만 `WorkspaceModePolicy` / `WorkspacePreparationMode`는 언급 없음.

**실제 결정(Issue #105)**: `WorkspaceModePolicy.swift`는 모든 모드 관련 UI 문자열, 동작 플래그의 단일 소유자로서 Pipeline, PreflightCheck, ConsentModal, PromptView가 모두 의존한다.

**정정 방향**: §20 Core Modules 표에 `WorkspaceModePolicy | 실행 모드 결정 (복사/직접) + 전체 모드 관련 문자열` 행 추가.

---

## 남은 OAuth 진입 마찰점 (테스트 미보장, 개선 후보)

### 마찰점 1 — CodexLoginRunner.runLoginProcess의 stderr 미노출

`Process()`로 `codex login`을 실행할 때 `readabilityHandler`는 stdout만 읽는다. stderr에 출력되는 실패 원인(네트워크 오류, 인증 서버 거부 등)은 사용자에게 노출되지 않는다. 현재 테스트는 `readabilityHandler`가 있다는 것만 확인하고 stderr 캡처를 강제하지 않는다.

**증상**: `codex login` 실패 시 사용자는 "로그인 완료"도 아니고 구체적 실패 이유도 모르는 상태에서 "다시 확인" 버튼만 보게 될 수 있다.

**개선 후보**: `standardError`에도 `readabilityHandler`를 추가해 실패 메시지를 수집하고 `isRunning = false` 전환 시 `errorMessage`에 표시.

---

### 마찰점 2 — `codex login` PATH 불일치 가능성

`PreflightCheck.firstWorkingCodexExecutableURL`은 `/opt/homebrew/bin/codex`, `.bun/bin/codex` 등을 탐색한다. 그러나 `CodexLoginRunner`의 `Process`는 `process.arguments = ["-lc", "codex login"]`으로 `zsh`의 login shell을 통해 `codex`를 찾는다. 두 경로 해석이 다른 Codex 바이너리를 찾는 엣지 케이스가 있다.

**증상**: Preflight는 `/opt/homebrew/bin/codex`로 설치 확인 → 통과. 로그인 시 `zsh -lc "codex login"`이 다른 경로(또는 NVM/bun 설치본)를 찾아 다른 버전으로 로그인 → 인증 상태 불일치.

**개선 후보**: `CodexLoginRunner`도 `PreflightCheck.firstWorkingCodexExecutableURL`이 반환한 절대경로를 사용하도록 통일. 현재 테스트는 `process.arguments = ["-lc", "codex login"]` 형태만 강제하고 절대경로 일치를 검증하지 않는다.

---

### 마찰점 3 — `refreshExistingLoginStatus` 실패 시 UI 상태 미정의

`test_issue_79_existing_auth_is_checked_before_launching_browser_login`은 `refreshExistingLoginStatus`가 존재하고 `.task`에서 호출됨을 확인한다. 그러나 `refreshExistingLoginStatus` 실행 중 Codex CLI 자체가 없거나 timeout이 발생한 경우의 UI 상태(로딩 스피너? 버튼 활성화 여부?)는 테스트로 보장되지 않는다.

**증상**: 앱 최초 실행 직후 Preflight 뷰에서 Codex가 설치되지 않은 상태라면 `refreshExistingLoginStatus`가 시간 초과 없이 무한 대기하거나, isRunning=false로 즉시 전환해 사용자가 인증 상태를 알 수 없다.

**개선 후보**: `refreshExistingLoginStatus`에 `PreflightCheck.codexCommandTimeout(= 4초)` 제한을 적용하고 실패 시 `isAuthenticated = false`로 명시 전환하는 테스트 추가.

---

### 마찰점 4 — OpenRouter OAuth 완료 후 패널 포커스 복원 타이밍

`test_issue_29_panel_reopens_and_survives_oauth_roundtrip`은 `bringPromptToFront`와 `NSApp.activate`가 `ProviderConnectView.swift`에 있음을 확인하지만, OAuth 완료 콜백 시점(localhost callback server 응답 후)에 실제로 `bringPromptToFront`가 호출되는지는 UI 통합 테스트 없이는 보장할 수 없다. 로컬 callback 서버(`NWListener`)가 코드를 받은 직후 패널이 자동으로 앞으로 나오지 않을 수 있다.

**개선 후보**: `OpenRouterPKCE.swift`의 code 수신 completion handler에서 `FolderTrailAppController.shared.bringPromptToFront()` 호출을 강제하는 smoke 또는 text search 테스트 추가.

---

### 마찰점 5 — OpenRouter API key exchange 실패 시 에러 복구 UX 미보장

`test_openrouter_provider_connect_contract`는 PKCE 흐름의 구현 요소(SHA-256, NWListener, code 추출)를 확인하지만, `https://openrouter.ai/api/v1/auth/keys` 호출이 실패했을 때 사용자가 보는 상태(`.failed` 케이스 메시지, 재시도 버튼)는 테스트로 보장되지 않는다.

**개선 후보**: `OpenRouterProviderSettings`의 `case failed` 분기에서 사용자 가이드 문구와 "다시 연결" 버튼 접근성을 검증하는 테스트 추가.
