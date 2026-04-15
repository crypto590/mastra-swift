import Foundation

public extension MastraClient {
    /// Returns a `Tool` handle for the given server-registered tool id.
    /// Mirrors JS `client.getTool(toolId)`.
    ///
    /// Note: this is the *server-level* tool resource. For caller-defined
    /// tools that the server asks the client to execute during
    /// `generate`/`stream`, use `ClientTool`.
    nonisolated func tool(id: String) -> Tool {
        Tool(base: base, toolId: id)
    }

    /// Mirrors JS `client.listTools(requestContext?)` → `GET /tools`.
    /// The per-call `requestContext` (if any) is base64-encoded and appended
    /// as the `requestContext` query item, on top of any configuration-level
    /// request context that `BaseResource` injects.
    nonisolated func listTools(
        requestContext: RequestContext? = nil
    ) async throws -> [String: GetToolResponse] {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return try await base.request("/tools", query: query)
    }
}
