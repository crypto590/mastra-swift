import Foundation

/// Equivalent of JS `StoredScorer` resource.
public struct StoredScorer: Sendable {
    public let storedScorerId: String
    let base: BaseResource

    init(base: BaseResource, storedScorerId: String) {
        self.base = base
        self.storedScorerId = storedScorerId
    }

    private var rootPath: String { "/stored/scorers/\(storedScorerId)" }
    private var versionsPath: String { "\(rootPath)/versions" }

    // MARK: - Details / update / delete

    public func details(
        status: StoredResourceStatus? = nil
    ) async throws -> StoredScorerResponse {
        var items: [URLQueryItem] = []
        if let status { items.append(.init(name: "status", value: status.rawValue)) }
        return try await base.request(rootPath, query: items)
    }

    public func update(
        _ params: UpdateStoredScorerParams
    ) async throws -> StoredScorerResponse {
        try await base.request(rootPath, method: .PATCH, body: .json(params.body()))
    }

    public func delete() async throws -> DeleteStoredScorerResponse {
        try await base.request(rootPath, method: .DELETE)
    }

    // MARK: - Version methods

    public func listVersions(
        _ params: ListScorerVersionsParams = .init()
    ) async throws -> ListScorerVersionsResponse {
        try await base.request(versionsPath, query: params.queryItems)
    }

    public func createVersion(
        _ params: CreateScorerVersionParams = .init()
    ) async throws -> ScorerVersionResponse {
        try await base.request(versionsPath, method: .POST, body: .json(params.body()))
    }

    public func getVersion(versionId: String) async throws -> ScorerVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)")
    }

    public func activateVersion(versionId: String) async throws -> ActivateScorerVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/activate", method: .POST)
    }

    /// Mirrors JS `storedScorer.restoreVersion(versionId)`. Returns a
    /// `ScorerVersionResponse` (the newly created version).
    public func restoreVersion(versionId: String) async throws -> ScorerVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/restore", method: .POST)
    }

    public func deleteVersion(versionId: String) async throws -> DeleteScorerVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)", method: .DELETE)
    }

    public func compareVersions(
        fromId: String,
        toId: String
    ) async throws -> CompareScorerVersionsResponse {
        try await base.request(
            "\(versionsPath)/compare",
            query: [
                URLQueryItem(name: "from", value: fromId),
                URLQueryItem(name: "to", value: toId),
            ]
        )
    }
}
