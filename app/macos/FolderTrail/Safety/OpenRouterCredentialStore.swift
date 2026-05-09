import Foundation

struct OpenRouterCredentialStore {
    typealias Load = () throws -> String?
    typealias Save = (String) throws -> Void
    typealias Delete = () throws -> Void

    static let keychain = OpenRouterCredentialStore(
        load: OpenRouterKeychain.load,
        save: OpenRouterKeychain.save,
        delete: OpenRouterKeychain.delete
    )

    private let load: Load
    private let save: Save
    private let delete: Delete

    init(
        load: @escaping Load,
        save: @escaping Save,
        delete: @escaping Delete
    ) {
        self.load = load
        self.save = save
        self.delete = delete
    }

    func loadAPIKey() throws -> String? {
        let trimmed = try load()?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    func saveAPIKey(_ rawKey: String) throws {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OpenRouterKeychain.KeychainError.invalidSecret
        }
        try save(trimmed)
    }

    func deleteAPIKey() throws {
        try delete()
    }
}
