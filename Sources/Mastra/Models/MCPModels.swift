import Foundation

// MARK: - Server info

/// Mirrors `ServerInfo` from `@mastra/core/mcp` — the summary entry returned
/// by `client.getMcpServers()`. Extra fields returned by the server are
/// preserved via `additional`.
public struct ServerInfo: Sendable, Codable {
    public let id: String
    public let name: String
    public let version_detail: ServerVersionDetail?

    public init(
        id: String,
        name: String,
        version_detail: ServerVersionDetail? = nil
    ) {
        self.id = id
        self.name = name
        self.version_detail = version_detail
    }
}

/// Mirrors the `version_detail` sub-object on `ServerInfo`.
public struct ServerVersionDetail: Sendable, Codable {
    public let version: String
    public let release_date: String?
    public let is_latest: Bool?

    public init(version: String, release_date: String? = nil, is_latest: Bool? = nil) {
        self.version = version
        self.release_date = release_date
        self.is_latest = is_latest
    }
}

// MARK: - Server detail info

/// Mirrors `ServerDetailInfo` from `@mastra/core/mcp`. Extends `ServerInfo`
/// with optional description/package/remote fields. Extra fields are left to
/// `JSONValue` because the upstream shape (packages/remotes) is
/// server-defined and deeply nested.
public struct ServerDetailInfo: Sendable, Codable {
    public let id: String
    public let name: String
    public let version_detail: ServerVersionDetail?
    public let description: String?
    public let package_canonical: String?
    public let packages: [JSONValue]?
    public let remotes: [JSONValue]?

    public init(
        id: String,
        name: String,
        version_detail: ServerVersionDetail? = nil,
        description: String? = nil,
        package_canonical: String? = nil,
        packages: [JSONValue]? = nil,
        remotes: [JSONValue]? = nil
    ) {
        self.id = id
        self.name = name
        self.version_detail = version_detail
        self.description = description
        self.package_canonical = package_canonical
        self.packages = packages
        self.remotes = remotes
    }
}

// MARK: - Tool list

/// Mirrors JS `McpToolInfo` — the per-entry summary returned by
/// `client.getMcpServerTools(serverId:)`.
public struct McpToolInfo: Sendable, Codable {
    public let id: String?
    public let name: String?
    public let description: String?
    /// JSON-Schema serialized as a string (matches JS `inputSchema: string`).
    public let inputSchema: String?
    /// Mirrors JS `toolType?: MCPToolType`. Kept as a string — the upstream
    /// enum is open and server-defined.
    public let toolType: String?

    public init(
        id: String? = nil,
        name: String? = nil,
        description: String? = nil,
        inputSchema: String? = nil,
        toolType: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.toolType = toolType
    }
}

// MARK: - Response wrappers

/// Mirrors JS `McpServerListResponse` — the envelope returned by
/// `client.getMcpServers()`.
public struct McpServerListResponse: Sendable, Codable {
    public let servers: [ServerInfo]
    public let next: String?
    public let total_count: Int

    public init(servers: [ServerInfo], next: String?, total_count: Int) {
        self.servers = servers
        self.next = next
        self.total_count = total_count
    }
}

/// Mirrors JS `McpServerToolListResponse` — the envelope returned by
/// `client.getMcpServerTools()`.
public struct McpServerToolListResponse: Sendable, Codable {
    public let tools: [McpToolInfo]

    public init(tools: [McpToolInfo]) { self.tools = tools }
}

// MARK: - Pagination

/// Mirrors the parameters of JS `client.getMcpServers({ page?, perPage?,
/// offset?, limit? })`. `offset` and `limit` are forwarded for legacy server
/// compatibility.
public struct McpServersParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var offset: Int?
    public var limit: Int?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        offset: Int? = nil,
        limit: Int? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.offset = offset
        self.limit = limit
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        // Legacy support: forwarded as-is, matching JS behavior.
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        if let offset { items.append(.init(name: "offset", value: String(offset))) }
        return items
    }
}

// MARK: - Execute params

/// Mirrors JS `MCPTool.execute({ data?, requestContext? })`. Provided for
/// callers that prefer a value-type argument.
public struct ExecuteMCPToolParams: Sendable {
    public var data: JSONValue?
    public var requestContext: RequestContext?

    public init(data: JSONValue? = nil, requestContext: RequestContext? = nil) {
        self.data = data
        self.requestContext = requestContext
    }
}
