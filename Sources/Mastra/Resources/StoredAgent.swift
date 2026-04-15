import Foundation

/// Equivalent of JS `StoredAgent` resource. Wraps a single stored agent id
/// and exposes the per-resource endpoints (details, update, delete) plus the
/// full version CRUD + activate/restore/compare surface.
///
/// Acquire via `MastraClient.storedAgent(id:)`.
public struct StoredAgent: Sendable {
    public let storedAgentId: String
    let base: BaseResource

    init(base: BaseResource, storedAgentId: String) {
        self.base = base
        self.storedAgentId = storedAgentId
    }

    private var rootPath: String { "/stored/agents/\(storedAgentId)" }
    private var versionsPath: String { "\(rootPath)/versions" }

    // MARK: - Details / update / delete

    /// Mirrors JS `storedAgent.details(requestContext?, { status? })` →
    /// `GET /stored/agents/:id`.
    public func details(
        status: StoredResourceStatus? = nil
    ) async throws -> StoredAgentResponse {
        var items: [URLQueryItem] = []
        if let status { items.append(.init(name: "status", value: status.rawValue)) }
        return try await base.request(rootPath, query: items)
    }

    /// Mirrors JS `storedAgent.update(params)` → `PATCH /stored/agents/:id`.
    public func update(
        _ params: UpdateStoredAgentParams
    ) async throws -> StoredAgentResponse {
        try await base.request(rootPath, method: .PATCH, body: .json(params.body()))
    }

    /// Mirrors JS `storedAgent.delete()` → `DELETE /stored/agents/:id`.
    public func delete() async throws -> DeleteStoredAgentResponse {
        try await base.request(rootPath, method: .DELETE)
    }

    // MARK: - Version methods

    /// Mirrors JS `storedAgent.listVersions(params?)` →
    /// `GET /stored/agents/:id/versions`.
    public func listVersions(
        _ params: ListAgentVersionsParams = .init()
    ) async throws -> ListAgentVersionsResponse {
        try await base.request(versionsPath, query: params.queryItems)
    }

    /// Mirrors JS `storedAgent.createVersion(params?)` →
    /// `POST /stored/agents/:id/versions`.
    public func createVersion(
        _ params: CreateStoredAgentVersionParams = .init()
    ) async throws -> AgentVersionResponse {
        try await base.request(versionsPath, method: .POST, body: .json(params.body()))
    }

    /// Mirrors JS `storedAgent.getVersion(versionId)` →
    /// `GET /stored/agents/:id/versions/:versionId`.
    public func getVersion(versionId: String) async throws -> AgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)")
    }

    /// Mirrors JS `storedAgent.activateVersion(versionId)` →
    /// `POST /stored/agents/:id/versions/:versionId/activate`.
    public func activateVersion(versionId: String) async throws -> ActivateAgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/activate", method: .POST)
    }

    /// Mirrors JS `storedAgent.restoreVersion(versionId)` →
    /// `POST /stored/agents/:id/versions/:versionId/restore`. JS returns an
    /// `AgentVersionResponse` directly (the newly created version).
    public func restoreVersion(versionId: String) async throws -> AgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/restore", method: .POST)
    }

    /// Mirrors JS `storedAgent.deleteVersion(versionId)` →
    /// `DELETE /stored/agents/:id/versions/:versionId`.
    public func deleteVersion(versionId: String) async throws -> DeleteAgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)", method: .DELETE)
    }

    /// Mirrors JS `storedAgent.compareVersions(fromId, toId)` →
    /// `GET /stored/agents/:id/versions/compare?from=…&to=…`.
    public func compareVersions(
        fromId: String,
        toId: String
    ) async throws -> CompareAgentVersionsResponse {
        try await base.request(
            "\(versionsPath)/compare",
            query: [
                URLQueryItem(name: "from", value: fromId),
                URLQueryItem(name: "to", value: toId),
            ]
        )
    }
}
