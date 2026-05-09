import Foundation

enum ProviderReadinessRequirement: Equatable {
    case required
    case optional
}

struct ProviderReadinessItem: Equatable {
    let title: String
    let requirement: ProviderReadinessRequirement
    let result: PreflightCheckResult

    var isReady: Bool {
        result.isPassed
    }
}

struct ProviderReadiness: Equatable {
    let openRouter: ProviderReadinessItem
    let codexLocalHelper: ProviderReadinessItem

    var canProceed: Bool {
        openRouter.isReady
    }

    static func evaluate(
        openRouterAPIKey: () throws -> String?,
        codexAuthenticated: () -> Bool
    ) rethrows -> ProviderReadiness {
        let rawKey = try openRouterAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let openRouterResult: PreflightCheckResult = rawKey?.isEmpty == false
            ? .passed
            : .failed(reason: "OpenRouter를 연결해야 AI 정리를 시작할 수 있습니다.")

        let codexResult: PreflightCheckResult = codexAuthenticated()
            ? .passed
            : .failed(reason: "Codex / ChatGPT OAuth는 선택 사항입니다. 없어도 OpenRouter로 먼저 진행할 수 있습니다.")

        return ProviderReadiness(
            openRouter: ProviderReadinessItem(
                title: "OpenRouter",
                requirement: .required,
                result: openRouterResult
            ),
            codexLocalHelper: ProviderReadinessItem(
                title: "Codex / ChatGPT",
                requirement: .optional,
                result: codexResult
            )
        )
    }

    static func promptStatus(openRouterConnected: Bool) -> ProviderReadiness {
        ProviderReadiness(
            openRouter: ProviderReadinessItem(
                title: "OpenRouter",
                requirement: .required,
                result: openRouterConnected
                    ? .passed
                    : .failed(reason: "OpenRouter를 연결해야 AI 정리를 시작할 수 있습니다.")
            ),
            codexLocalHelper: ProviderReadinessItem(
                title: "Codex / ChatGPT",
                requirement: .optional,
                result: .failed(reason: "Codex / ChatGPT OAuth는 선택 사항입니다. 없어도 OpenRouter로 먼저 진행할 수 있습니다.")
            )
        )
    }
}
