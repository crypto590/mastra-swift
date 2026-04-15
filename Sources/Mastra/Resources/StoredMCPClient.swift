import Foundation

/// Equivalent of JS `StoredMCPClient` resource. This resource does not
/// expose versioning endpoints — only `details` / `update` / `delete`.
public struct StoredMCPClient: Sendable {
    public let storedMCPClientId: String
    let base: BaseResource

    init(base: BaseResource, storedMCPClientId: String) {
        self.base = base
        self.storedMCPClientId = storedMCPClientId
    }

    private var rootPath: String { "/stored/mcp-clients/\(storedMCPClientId)" }

    /// Mirrors JS `storedMCPClient.details()`.
    public func details() async throws -> StoredMCPClientResponse {
        try await base.request(rootPath)
    }

    /// Mirrors JS `storedMCPClient.update(params)`.
    public func update(
        _ params: UpdateStoredMCPClientParams
    ) async throws -> StoredMCPClientResponse {
        try await base.request(rootPath, method: .PATCH, body: .json(params.body()))
    }

    /// Mirrors JS `storedMCPClient.delete()`.
    public func delete() async throws -> DeleteStoredMCPClientResponse {
        try await base.request(rootPath, method: .DELETE)
    }
}
