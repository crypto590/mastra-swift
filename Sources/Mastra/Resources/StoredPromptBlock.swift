import Foundation

/// Equivalent of JS `StoredPromptBlock` resource.
public struct StoredPromptBlock: Sendable {
    public let storedPromptBlockId: String
    let base: BaseResource

    init(base: BaseResource, storedPromptBlockId: String) {
        self.base = base
        self.storedPromptBlockId = storedPromptBlockId
    }

    private var rootPath: String { "/stored/prompt-blocks/\(storedPromptBlockId)" }
    private var versionsPath: String { "\(rootPath)/versions" }

    // MARK: - Details / update / delete

    /// Mirrors JS `storedPromptBlock.details(requestContext?, { status? })`.
    public func details(
        status: StoredResourceStatus? = nil
    ) async throws -> StoredPromptBlockResponse {
        var items: [URLQueryItem] = []
        if let status { items.append(.init(name: "status", value: status.rawValue)) }
        return try await base.request(rootPath, query: items)
    }

    /// Mirrors JS `storedPromptBlock.update(params)` →
    /// `PATCH /stored/prompt-blocks/:id`.
    public func update(
        _ params: UpdateStoredPromptBlockParams
    ) async throws -> StoredPromptBlockResponse {
        try await base.request(rootPath, method: .PATCH, body: .json(params.body()))
    }

    /// Mirrors JS `storedPromptBlock.delete()` →
    /// `DELETE /stored/prompt-blocks/:id`.
    public func delete() async throws -> DeleteStoredPromptBlockResponse {
        try await base.request(rootPath, method: .DELETE)
    }

    // MARK: - Version methods

    public func listVersions(
        _ params: ListPromptBlockVersionsParams = .init()
    ) async throws -> ListPromptBlockVersionsResponse {
        try await base.request(versionsPath, query: params.queryItems)
    }

    public func createVersion(
        _ params: CreatePromptBlockVersionParams = .init()
    ) async throws -> PromptBlockVersionResponse {
        try await base.request(versionsPath, method: .POST, body: .json(params.body()))
    }

    public func getVersion(versionId: String) async throws -> PromptBlockVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)")
    }

    public func activateVersion(versionId: String) async throws -> ActivatePromptBlockVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/activate", method: .POST)
    }

    /// Mirrors JS `storedPromptBlock.restoreVersion(versionId)`. JS returns
    /// a `PromptBlockVersionResponse` (the newly created version).
    public func restoreVersion(versionId: String) async throws -> PromptBlockVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/restore", method: .POST)
    }

    public func deleteVersion(versionId: String) async throws -> DeletePromptBlockVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)", method: .DELETE)
    }

    public func compareVersions(
        fromId: String,
        toId: String
    ) async throws -> ComparePromptBlockVersionsResponse {
        try await base.request(
            "\(versionsPath)/compare",
            query: [
                URLQueryItem(name: "from", value: fromId),
                URLQueryItem(name: "to", value: toId),
            ]
        )
    }
}
