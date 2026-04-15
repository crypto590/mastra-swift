import Foundation

/// Equivalent of JS `MCPTool` resource from
/// `client-js/src/resources/mcp-tool.ts`. Represents a specific tool on a
/// specific MCP server. Acquire via `MastraClient.mcpServerTool(serverId:toolId:)`.
public struct MCPTool: Sendable {
    public let serverId: String
    public let toolId: String
    let base: BaseResource

    init(base: BaseResource, serverId: String, toolId: String) {
        self.base = base
        self.serverId = serverId
        self.toolId = toolId
    }

    /// Mirrors JS `mcpTool.details(requestContext?)` →
    /// `GET /mcp/:serverId/tools/:toolId`. Per-call `requestContext` is
    /// base64-encoded and appended as the `requestContext` query item,
    /// matching the JS `requestContextQueryString` helper.
    public func details(
        requestContext: RequestContext? = nil
    ) async throws -> McpToolInfo {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/mcp/\(serverId)/tools/\(toolId)",
            query: query
        )
    }

    /// Mirrors JS `mcpTool.execute({ data?, requestContext? })` →
    /// `POST /mcp/:serverId/tools/:toolId/execute`.
    ///
    /// Matches JS body-shape precisely: the body is omitted entirely when both
    /// `data` and `requestContext` are `nil`; otherwise, only the provided
    /// fields are included.
    public func execute(
        data: JSONValue? = nil,
        requestContext: RequestContext? = nil
    ) async throws -> JSONValue {
        var obj: JSONObject = [:]
        if let data { obj["data"] = data }
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        let body: HTTPBody? = obj.isEmpty ? nil : .json(.object(obj))
        return try await base.request(
            "/mcp/\(serverId)/tools/\(toolId)/execute",
            method: .POST,
            body: body
        )
    }

    /// Convenience overload taking the value-type params struct.
    public func execute(_ params: ExecuteMCPToolParams) async throws -> JSONValue {
        try await execute(data: params.data, requestContext: params.requestContext)
    }
}
