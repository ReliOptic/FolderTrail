import Foundation

enum WorkspacePreparationMode: String, CaseIterable, Equatable {
    case copiedWorkspace
    case directSource

    var modePickerTitle: String {
        switch self {
        case .copiedWorkspace:
            return "안전 모드"
        case .directSource:
            return "빠른 모드"
        }
    }

    var modeDescription: String {
        switch self {
        case .copiedWorkspace:
            return "복사본에서 안전하게 정리합니다."
        case .directSource:
            return "복사 시간을 건너뛰며 원본 폴더가 직접 변경될 수 있습니다."
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .copiedWorkspace:
            return "복사본으로 시작"
        case .directSource:
            return "원본에서 바로 시작"
        }
    }

    var requiresPreflightBeforeConsent: Bool {
        switch self {
        case .copiedWorkspace:
            return true
        case .directSource:
            return false
        }
    }

    var preflightWorkspaceTitle: String {
        switch self {
        case .copiedWorkspace:
            return "작업 복사본을 만들 수 있음"
        case .directSource:
            return "원본 폴더에 쓸 수 있음"
        }
    }

    var consentHeadline: String {
        switch self {
        case .copiedWorkspace:
            return "원본 폴더는 변경하지 않습니다"
        case .directSource:
            return "원본 폴더에서 바로 진행합니다"
        }
    }

    var consentDescription: String {
        switch self {
        case .copiedWorkspace:
            return "FolderTrail은 별도 작업 폴더를 만든 뒤 그 안에서 정리 계획을 실행합니다."
        case .directSource:
            return "복사 시간을 건너뛰는 대신 정리 작업이 선택한 폴더에 바로 적용됩니다."
        }
    }

    var consentAccentIsWarning: Bool {
        self == .directSource
    }

    var workspaceReadyStepText: String {
        switch self {
        case .copiedWorkspace:
            return "복사본 준비 중"
        case .directSource:
            return "원본 준비 중"
        }
    }
}
