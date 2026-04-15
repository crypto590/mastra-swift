import Foundation

/// Equivalent of JS `Workspace` resource. Every method maps 1:1 to an endpoint
/// on the Mastra workspace API; paths match the JS client exactly
/// (including `encodeURIComponent` on the workspace id). Acquire an instance
/// via `MastraClient.workspace(id:)`.
///
/// Provides:
/// - Info: `info()`
/// - Filesystem: `readFile`, `writeFile`, `listFiles`, `delete`, `mkdir`, `stat`
/// - Search/Index: `search`, `index`
/// - Skills: `listSkills`, `searchSkills`, `skill(name:path:)` / `getSkill(...)`
public struct Workspace: Sendable {
    public let workspaceId: String
    let base: BaseResource

    init(base: BaseResource, workspaceId: String) {
        self.base = base
        self.workspaceId = workspaceId
    }

    // MARK: - Path helpers

    /// Equivalent of `encodeURIComponent` from JS — percent-encodes everything
    /// except unreserved characters.
    private func encodeComponent(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? s
    }

    private var basePath: String {
        "/workspaces/\(encodeComponent(workspaceId))"
    }

    // MARK: - Workspace Info

    /// Mirrors JS `workspace.info()` → `GET /workspaces/:id`.
    public func info() async throws -> WorkspaceInfoResponse {
        try await base.request(basePath)
    }

    // MARK: - Filesystem Operations

    /// Mirrors JS `workspace.readFile(path, encoding?)` →
    /// `GET /workspaces/:id/fs/read?path=...`.
    public func readFile(
        path: String,
        encoding: String? = nil
    ) async throws -> WorkspaceFsReadResponse {
        var query: [URLQueryItem] = [.init(name: "path", value: path)]
        if let encoding {
            query.append(.init(name: "encoding", value: encoding))
        }
        return try await base.request("\(basePath)/fs/read", query: query)
    }

    /// Mirrors JS `workspace.writeFile(path, content, options?)` →
    /// `POST /workspaces/:id/fs/write`.
    public func writeFile(
        path: String,
        content: String,
        options: WorkspaceWriteOptions? = nil
    ) async throws -> WorkspaceFsWriteResponse {
        var obj: JSONObject = [
            "path": .string(path),
            "content": .string(content),
        ]
        if let encoding = options?.encoding {
            obj["encoding"] = .string(encoding.rawValue)
        }
        if let recursive = options?.recursive {
            obj["recursive"] = .bool(recursive)
        }
        return try await base.request(
            "\(basePath)/fs/write",
            method: .POST,
            body: .json(.object(obj))
        )
    }

    /// Mirrors JS `workspace.listFiles(path, recursive?)` →
    /// `GET /workspaces/:id/fs/list?path=...&recursive=...`.
    public func listFiles(
        path: String,
        recursive: Bool? = nil
    ) async throws -> WorkspaceFsListResponse {
        var query: [URLQueryItem] = [.init(name: "path", value: path)]
        if let recursive {
            query.append(.init(name: "recursive", value: String(recursive)))
        }
        return try await base.request("\(basePath)/fs/list", query: query)
    }

    /// Mirrors JS `workspace.delete(path, options?)` →
    /// `DELETE /workspaces/:id/fs/delete?path=...`.
    public func delete(
        path: String,
        options: WorkspaceDeleteOptions? = nil
    ) async throws -> WorkspaceFsDeleteResponse {
        var query: [URLQueryItem] = [.init(name: "path", value: path)]
        if let recursive = options?.recursive {
            query.append(.init(name: "recursive", value: String(recursive)))
        }
        if let force = options?.force {
            query.append(.init(name: "force", value: String(force)))
        }
        return try await base.request(
            "\(basePath)/fs/delete",
            method: .DELETE,
            query: query
        )
    }

    /// Mirrors JS `workspace.mkdir(path, recursive?)` →
    /// `POST /workspaces/:id/fs/mkdir`.
    public func mkdir(
        path: String,
        recursive: Bool? = nil
    ) async throws -> WorkspaceFsMkdirResponse {
        var obj: JSONObject = ["path": .string(path)]
        if let recursive { obj["recursive"] = .bool(recursive) }
        return try await base.request(
            "\(basePath)/fs/mkdir",
            method: .POST,
            body: .json(.object(obj))
        )
    }

    /// Mirrors JS `workspace.stat(path)` →
    /// `GET /workspaces/:id/fs/stat?path=...`.
    public func stat(path: String) async throws -> WorkspaceFsStatResponse {
        try await base.request(
            "\(basePath)/fs/stat",
            query: [.init(name: "path", value: path)]
        )
    }

    // MARK: - Search Operations

    /// Mirrors JS `workspace.search(params)` →
    /// `GET /workspaces/:id/search?query=...&topK=...&mode=...&minScore=...`.
    ///
    /// Note: the JS client uses GET despite the resource method being called
    /// `search` (the query is passed via URL search params). We preserve that
    /// wire contract here.
    public func search(
        _ params: WorkspaceSearchParams
    ) async throws -> WorkspaceSearchResponse {
        try await base.request("\(basePath)/search", query: params.queryItems)
    }

    /// Mirrors JS `workspace.index(params)` → `POST /workspaces/:id/index`.
    public func index(
        _ params: WorkspaceIndexParams
    ) async throws -> WorkspaceIndexResponse {
        try await base.request(
            "\(basePath)/index",
            method: .POST,
            body: .json(params.body())
        )
    }

    // MARK: - Skills Operations

    /// Mirrors JS `workspace.listSkills()` → `GET /workspaces/:id/skills`.
    public func listSkills() async throws -> ListSkillsResponse {
        try await base.request("\(basePath)/skills")
    }

    /// Mirrors JS `workspace.searchSkills(params)` →
    /// `GET /workspaces/:id/skills/search?query=...&...`.
    public func searchSkills(
        _ params: SearchSkillsParams
    ) async throws -> SearchSkillsResponse {
        try await base.request("\(basePath)/skills/search", query: params.queryItems)
    }

    /// Mirrors JS `workspace.getSkill(skillName, skillPath?)`. Returns a
    /// `WorkspaceSkill` handle — no network call is made.
    public func skill(name: String, path: String? = nil) -> WorkspaceSkill {
        WorkspaceSkill(base: base, workspaceId: workspaceId, skillName: name, skillPath: path)
    }

    /// Alias of `skill(name:path:)` that matches the JS method name 1:1.
    public func getSkill(name: String, path: String? = nil) -> WorkspaceSkill {
        skill(name: name, path: path)
    }
}

/// Equivalent of JS `WorkspaceSkillResource`. Exposes operations on a single
/// skill inside a workspace.
public struct WorkspaceSkill: Sendable {
    public let workspaceId: String
    public let skillName: String
    public let skillPath: String?
    let base: BaseResource

    init(
        base: BaseResource,
        workspaceId: String,
        skillName: String,
        skillPath: String?
    ) {
        self.base = base
        self.workspaceId = workspaceId
        self.skillName = skillName
        self.skillPath = skillPath
    }

    private func encodeComponent(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? s
    }

    /// Mirrors JS private `basePath` on `WorkspaceSkillResource`.
    private var basePath: String {
        "/workspaces/\(encodeComponent(workspaceId))/skills/\(encodeComponent(skillName))"
    }

    /// Mirrors the optional `?path=...` disambiguator that the JS resource
    /// appends to every request.
    private var pathQueryItems: [URLQueryItem] {
        guard let skillPath else { return [] }
        return [.init(name: "path", value: skillPath)]
    }

    /// Mirrors JS `skill.details()` → `GET /workspaces/:id/skills/:name`.
    public func details() async throws -> Skill {
        try await base.request(basePath, query: pathQueryItems)
    }

    /// Mirrors JS `skill.listReferences()` →
    /// `GET /workspaces/:id/skills/:name/references`.
    public func listReferences() async throws -> ListSkillReferencesResponse {
        try await base.request("\(basePath)/references", query: pathQueryItems)
    }

    /// Mirrors JS `skill.getReference(referencePath)` →
    /// `GET /workspaces/:id/skills/:name/references/:referencePath`.
    public func getReference(
        referencePath: String
    ) async throws -> GetSkillReferenceResponse {
        try await base.request(
            "\(basePath)/references/\(encodeComponent(referencePath))",
            query: pathQueryItems
        )
    }
}
