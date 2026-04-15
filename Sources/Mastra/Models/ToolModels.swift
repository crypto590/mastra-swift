import Foundation

// NOTE: `GetToolResponse` is already declared in `AgentModels.swift` (shared
// across the agent tools route and the top-level server tools route), matching
// JS `GetToolResponse` in `client-js/src/types.ts`. It lives there because
// `Agent.getTool(toolId:)` returns the same shape. Do not redeclare it here.

// MARK: - Tool list response

/// Mirrors JS `Record<string, GetToolResponse>` — the return type of
/// `client.listTools()`. Wrapped in a struct for type clarity in Swift.
public struct ListToolsResponse: Sendable {
    public let tools: [String: GetToolResponse]
    public init(_ tools: [String: GetToolResponse]) { self.tools = tools }
}

// MARK: - Tool execute params

/// Mirrors the parameters of JS `tool.execute({ data, runId?, requestContext? })`.
/// Provided for callers that prefer a value-type argument over trailing params.
public struct ExecuteToolParams: Sendable {
    public var data: JSONValue
    public var runId: String?
    public var requestContext: RequestContext?

    public init(
        data: JSONValue,
        runId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.data = data
        self.runId = runId
        self.requestContext = requestContext
    }
}
