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
        codexLocalHelper.isReady
    }

    static func evaluate(
        openRouterAPIKey: () throws -> String?,
        codexAuthenticated: () -> Bool
    ) rethrows -> ProviderReadiness {
        let rawKey = try openRouterAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let openRouterResult: PreflightCheckResult = rawKey?.isEmpty == false
            ? .passed
            : .failed(reason: "OpenRouter는 설정에서 연결할 수 있습니다.")

        let codexResult: PreflightCheckResult = codexAuthenticated()
            ? .passed
            : .failed(reason: "Codex 로그인이 필요합니다.")

        return ProviderReadiness(
            openRouter: ProviderReadinessItem(
                title: "OpenRouter",
                requirement: .optional,
                result: openRouterResult
            ),
            codexLocalHelper: ProviderReadinessItem(
                title: "Codex / ChatGPT",
                requirement: .required,
                result: codexResult
            )
        )
    }

    static func promptStatus(openRouterConnected: Bool) -> ProviderReadiness {
        ProviderReadiness(
            openRouter: ProviderReadinessItem(
                title: "OpenRouter",
                requirement: .optional,
                result: openRouterConnected
                    ? .passed
                    : .failed(reason: "OpenRouter는 설정에서 연결할 수 있습니다.")
            ),
            codexLocalHelper: ProviderReadinessItem(
                title: "Codex / ChatGPT",
                requirement: .required,
                result: .failed(reason: "Codex 로그인이 필요합니다.")
            )
        )
    }
}
