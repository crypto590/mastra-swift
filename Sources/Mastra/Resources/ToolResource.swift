import Foundation

/// Server-level tool resource. Mirrors JS `Tool` from
/// `client-js/src/resources/tool.ts`. Acquire via `MastraClient.tool(id:)`.
///
/// Not to be confused with `ClientTool` (in `Sources/Mastra/Client/Tool.swift`),
/// which represents a *caller-defined* tool that the Mastra server asks the
/// client to execute during a `generate`/`stream` loop. This `Tool` struct, in
/// contrast, is a remote handle for a tool *registered on the server*: it
/// fetches metadata (`details`) and invokes server-side execution (`execute`).
public struct Tool: Sendable {
    public let toolId: String
    let base: BaseResource

    init(base: BaseResource, toolId: String) {
        self.base = base
        self.toolId = toolId
    }

    /// Mirrors JS `tool.details(requestContext?)` → `GET /tools/:toolId`.
    /// Per-call `requestContext` is appended as a base64-encoded query item,
    /// in addition to any configuration-level requestContext that
    /// `BaseResource` already applies.
    public func details(
        requestContext: RequestContext? = nil
    ) async throws -> GetToolResponse {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/tools/\(toolId)",
            query: query
        )
    }

    /// Mirrors JS `tool.execute({ data, runId?, requestContext? })` →
    /// `POST /tools/:toolId/execute`.
    public func execute(
        data: JSONValue,
        runId: String? = nil,
        requestContext: RequestContext? = nil
    ) async throws -> JSONValue {
        var query: [URLQueryItem] = []
        if let runId {
            query.append(URLQueryItem(name: "runId", value: runId))
        }
        var bodyObject: JSONObject = ["data": data]
        if let requestContext {
            bodyObject["requestContext"] = .object(requestContext.entries)
        }
        return try await base.request(
            "/tools/\(toolId)/execute",
            method: .POST,
            query: query,
            body: .json(.object(bodyObject))
        )
    }
}
