import Foundation

public extension MastraClient {
    /// Mirrors JS `client.getMcpServers({ page?, perPage?, offset?, limit? })`
    /// → `GET /mcp/v0/servers`. `offset`/`limit` are forwarded for legacy
    /// server compatibility, matching the JS client.
    nonisolated func mcpServers(
        page: Int? = nil,
        perPage: Int? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> McpServerListResponse {
        let params = McpServersParams(page: page, perPage: perPage, offset: offset, limit: limit)
        return try await base.request("/mcp/v0/servers", query: params.queryItems)
    }

    /// Mirrors JS `client.getMcpServerDetails(serverId, { version? })` →
    /// `GET /mcp/v0/servers/:serverId`.
    nonisolated func mcpServer(
        id: String,
        version: String? = nil
    ) async throws -> ServerDetailInfo {
        var query: [URLQueryItem] = []
        if let version {
            query.append(URLQueryItem(name: "version", value: version))
        }
        return try await base.request("/mcp/v0/servers/\(id)", query: query)
    }

    /// Mirrors JS `client.getMcpServerTools(serverId)` →
    /// `GET /mcp/:serverId/tools`.
    nonisolated func mcpServerTools(
        serverId: String
    ) async throws -> McpServerToolListResponse {
        try await base.request("/mcp/\(serverId)/tools")
    }

    /// Mirrors JS `client.getMcpServerTool(serverId, toolId)` — returns an
    /// `MCPTool` handle for the given server/tool id pair.
    nonisolated func mcpServerTool(serverId: String, toolId: String) -> MCPTool {
        MCPTool(base: base, serverId: serverId, toolId: toolId)
    }
}
