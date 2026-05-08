import CryptoKit
import Foundation
import Network

enum OpenRouterPKCE {
    static let authorizationEndpoint = URL(string: "https://openrouter.ai/auth")!
    static let callbackURL = URL(string: "http://localhost:3000/openrouter/callback")!
    static let keyExchangeEndpoint = URL(string: "https://openrouter.ai/api/v1/auth/keys")!

    static func makeVerifier(byteCount: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URLString(from: Data(bytes))
    }

    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return base64URLString(from: Data(digest))
    }

    static func authorizationURL(
        verifier: String,
        state: String = UUID().uuidString
    ) -> URL {
        var components = URLComponents(url: authorizationEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "callback_url", value: callbackURL.absoluteString),
            URLQueryItem(name: "code_challenge", value: challenge(for: verifier)),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }

    private static func base64URLString(from data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

final class OpenRouterCallbackServer: @unchecked Sendable {
    enum CallbackError: Error {
        case listenerUnavailable
        case missingCode
    }

    private let port: UInt16
    private let queue = DispatchQueue(label: "dev.foldertrail.openrouter-callback")

    private var listener: NWListener?
    private var continuation: CheckedContinuation<String, Error>?
    private var pendingResult: Result<String, Error>?

    init(port: UInt16 = 3000) {
        self.port = port
    }

    func start() throws {
        guard listener == nil else { return }
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw CallbackError.listenerUnavailable
        }

        let listener = try NWListener(using: .tcp, on: endpointPort)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    func waitForCode() async throws -> String {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    if let result = self.pendingResult {
                        self.pendingResult = nil
                        continuation.resume(with: result)
                    } else {
                        self.continuation = continuation
                    }
                }
            }
        } onCancel: {
            self.stop()
        }
    }

    func stop() {
        queue.async {
            self.listener?.cancel()
            self.listener = nil
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self else { return }

            let code = data.flatMap(Self.codeParameter(from:))
            let response = Self.httpResponse(hasCode: code != nil)
            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })

            if let code {
                self.complete(.success(code))
            } else {
                self.complete(.failure(CallbackError.missingCode))
            }
        }
    }

    private func complete(_ result: Result<String, Error>) {
        if let continuation {
            self.continuation = nil
            continuation.resume(with: result)
        } else {
            pendingResult = result
        }
        listener?.cancel()
        listener = nil
    }

    private static func codeParameter(from data: Data) -> String? {
        guard
            let request = String(data: data, encoding: .utf8),
            let requestLine = request.split(separator: "\r\n", maxSplits: 1).first,
            let path = requestLine.split(separator: " ").dropFirst().first,
            let components = URLComponents(string: "http://localhost:3000\(path)")
        else {
            return nil
        }

        return components.queryItems?.first(where: { $0.name == "code" })?.value
    }

    private static func httpResponse(hasCode: Bool) -> String {
        let status = hasCode ? "200 OK" : "400 Bad Request"
        let body = hasCode
            ? "FolderTrail OpenRouter connection complete. You can close this tab."
            : "FolderTrail could not find an OpenRouter authorization code."

        return """
        HTTP/1.1 \(status)\r
        Content-Type: text/plain; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """
    }
}
