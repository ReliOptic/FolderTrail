import Foundation

struct ActionPlan: Codable, Equatable {
    let plan_version: String
    let provider: String
    let model: String
    let summary_ko: String
    let actions: [PlanAction]
}

struct PlanAction: Codable, Equatable {
    let type: String
    let path: String?
    let from: String?
    let to: String?
    let reason: String?
    let content: String?

    init(
        type: String,
        path: String? = nil,
        from: String? = nil,
        to: String? = nil,
        reason: String? = nil,
        content: String? = nil
    ) {
        self.type = type
        self.path = path
        self.from = from
        self.to = to
        self.reason = reason
        self.content = content
    }
}

enum PlannerAdapterError: Error, Equatable {
    case authFailure
    case networkFailure
    case invalidJSON
    case schemaMismatch
}

protocol PlannerAdapter {
    func plan(prompt: String, manifest: FolderManifest) async throws -> ActionPlan
}

final class OpenRouterPlannerAdapter: PlannerAdapter {
    static let defaultModel = "anthropic/claude-sonnet-4.6"
    static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    static let systemPrompt = """
    You are FolderTrail Planner. Your task is to generate a structured JSON action plan for organizing the given folder.

    Rules:
    - Do not include delete actions. Use mark_review_needed instead.
    - Only reference files within the provided workspace manifest.
    - Do not access parent directories or external paths.
    - Do not read or expose credentials, private keys, or sensitive files.
    - Return only valid JSON matching the action plan schema.
    - Write summary in Korean unless the user prompt specifies another language.
    """

    typealias Transport = (URLRequest) async throws -> (Data, URLResponse)

    private let model: String
    private let transport: Transport
    private let credentialStore: OpenRouterCredentialStore

    init(
        model: String = OpenRouterPlannerAdapter.defaultModel,
        credentialStore: OpenRouterCredentialStore = .keychain,
        transport: @escaping Transport = { request in
            try await URLSession.shared.data(for: request)
        }
    ) {
        self.model = model
        self.credentialStore = credentialStore
        self.transport = transport
    }

    func plan(prompt: String, manifest: FolderManifest) async throws -> ActionPlan {
        guard let rawKey = try credentialStore.loadAPIKey() else {
            throw PlannerAdapterError.authFailure
        }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(rawKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OpenRouterChatRequest(
                model: model,
                messages: [
                    OpenRouterMessage(role: "system", content: Self.systemPrompt),
                    OpenRouterMessage(role: "user", content: userMessage(prompt: prompt, manifest: manifest)),
                ]
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport(request)
        } catch {
            throw PlannerAdapterError.networkFailure
        }

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw PlannerAdapterError.authFailure
        }

        guard let chatResponse = try? JSONDecoder().decode(OpenRouterChatResponse.self, from: data),
              let content = chatResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8)
        else {
            throw PlannerAdapterError.invalidJSON
        }

        return try Self.decodeActionPlan(from: contentData)
    }

    static func decodeActionPlan(from data: Data) throws -> ActionPlan {
        let plan: ActionPlan
        do {
            plan = try JSONDecoder().decode(ActionPlan.self, from: data)
        } catch {
            throw PlannerAdapterError.invalidJSON
        }

        guard !plan.actions.isEmpty,
              plan.plan_version == "0.1",
              !plan.summary_ko.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw PlannerAdapterError.schemaMismatch
        }

        return plan
    }

    private func userMessage(prompt: String, manifest: FolderManifest) -> String {
        let manifestData = (try? JSONEncoder().encode(manifest)) ?? Data("{}".utf8)
        let manifestJSON = String(data: manifestData, encoding: .utf8) ?? "{}"
        return """
        User prompt:
        \(prompt)

        FolderManifest JSON:
        \(manifestJSON)
        """
    }
}

struct MockPlannerAdapter: PlannerAdapter {
    func plan(prompt: String, manifest: FolderManifest) async throws -> ActionPlan {
        ActionPlan(
            plan_version: "0.1",
            provider: "mock",
            model: "offline-mock",
            summary_ko: "오프라인 개발용 고정 계획입니다.",
            actions: [
                PlanAction(type: "write_summary", path: "FolderTrailSummary.md", content: "Mock plan for \(manifest.workspace_name)")
            ]
        )
    }
}

final class PlannerModelSettings: ObservableObject {
    static let curatedModels = [
        "anthropic/claude-sonnet-4.6",
        "anthropic/claude-opus-4.1",
        "openai/gpt-5.2",
        "google/gemini-3-pro-preview",
    ]

    @Published var selectedModel = OpenRouterPlannerAdapter.defaultModel
    @Published var customModel = ""

    var effectiveModel: String {
        let trimmed = customModel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? selectedModel : trimmed
    }
}

private struct OpenRouterChatRequest: Encodable {
    let model: String
    let messages: [OpenRouterMessage]
}

private struct OpenRouterMessage: Codable, Equatable {
    let role: String
    let content: String
}

private struct OpenRouterChatResponse: Decodable {
    let choices: [OpenRouterChoice]
}

private struct OpenRouterChoice: Decodable {
    let message: OpenRouterMessage
}
