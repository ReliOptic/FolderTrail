import Foundation

enum ProviderConnectionStatus: Equatable {
    case connected(maskedAPIKey: String)
    case notConnected
    case failed(String)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

@MainActor
final class OpenRouterProviderSettings: ObservableObject {
    static let shared = OpenRouterProviderSettings()

    @Published private(set) var status: ProviderConnectionStatus = .notConnected

    init() {
        refreshStatus()
    }

    var isConnected: Bool {
        status.isConnected
    }

    var maskedAPIKey: String {
        switch status {
        case .connected(let maskedValue):
            return maskedValue
        case .notConnected:
            return "Not connected"
        case .failed:
            return "Connection failed"
        }
    }

    func refreshStatus() {
        do {
            if let storedSecret = try OpenRouterKeychain.load(), !storedSecret.isEmpty {
                status = .connected(maskedAPIKey: mask(storedSecret))
            } else {
                status = .notConnected
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func saveManualAPIKey(_ rawKey: String) {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            status = .notConnected
            return
        }

        do {
            try OpenRouterKeychain.save(trimmed)
            status = .connected(maskedAPIKey: mask(trimmed))
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func connectWithBrowser(openURL: (URL) -> Void) async {
        let verifier = OpenRouterPKCE.makeVerifier()
        let callbackServer = OpenRouterCallbackServer()

        do {
            try callbackServer.start()
            openURL(OpenRouterPKCE.authorizationURL(verifier: verifier))
            let code = try await callbackServer.waitForCode()
            let response = try await exchangeAuthorizationCode(code, verifier: verifier)
            try OpenRouterKeychain.save(response.key)
            status = .connected(maskedAPIKey: mask(response.key))
        } catch {
            callbackServer.stop()
            status = .failed(error.localizedDescription)
        }
    }

    private func mask(_ secret: String) -> String {
        let suffix = secret.suffix(4)
        return "•••• \(suffix)"
    }

    private func exchangeAuthorizationCode(
        _ code: String,
        verifier: String
    ) async throws -> OpenRouterKeyExchangeResponse {
        var request = URLRequest(url: OpenRouterPKCE.keyExchangeEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OpenRouterKeyExchangeRequest(
                code: code,
                code_verifier: verifier,
                code_challenge_method: "S256"
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw OpenRouterProviderError.exchangeFailed(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(OpenRouterKeyExchangeResponse.self, from: data)
    }
}

private struct OpenRouterKeyExchangeRequest: Encodable {
    let code: String
    let code_verifier: String
    let code_challenge_method: String
}

private struct OpenRouterKeyExchangeResponse: Decodable {
    let key: String
}

private enum OpenRouterProviderError: LocalizedError {
    case exchangeFailed(Int)

    var errorDescription: String? {
        switch self {
        case .exchangeFailed(let statusCode):
            return "OpenRouter key exchange failed with HTTP \(statusCode)."
        }
    }
}
