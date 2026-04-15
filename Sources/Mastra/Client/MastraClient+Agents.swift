import Foundation

public extension MastraClient {
    /// Returns an `Agent` handle for the given agent id and optional version.
    /// Mirrors JS `client.getAgent(agentId, version?)`.
    nonisolated func agent(id: String, version: AgentVersionIdentifier? = nil) -> Agent {
        Agent(base: base, agentId: id, version: version)
    }

    /// Mirrors JS `client.listAgents(requestContext?, partial?)` →
    /// `GET /agents`. Returns a map from agent id to `GetAgentResponse`.
    nonisolated func listAgents(
        requestContext: RequestContext? = nil,
        partial: Bool = false
    ) async throws -> [String: GetAgentResponse] {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        if partial {
            query.append(.init(name: "partial", value: "true"))
        }
        return try await base.request("/agents", query: query)
    }

    /// Mirrors JS `client.listAgentsModelProviders()` →
    /// `GET /agents/providers`.
    nonisolated func listAgentsModelProviders() async throws -> ListAgentsModelProvidersResponse {
        try await base.request("/agents/providers")
    }

    /// Mirrors JS `client.getAgentBuilderActions()` →
    /// `GET /agent-builder/`. Returns the server's action map as `JSONValue`
    /// because the value shape (`WorkflowInfo`) is deeply nested and better
    /// modeled by the consumer.
    nonisolated func agentBuilderActions() async throws -> JSONValue {
        try await base.request("/agent-builder/")
    }

    /// Mirrors JS `client.getAgentBuilderAction(actionId)`.
    nonisolated func agentBuilderAction(id: String) -> AgentBuilder {
        AgentBuilder(base: base, actionId: id)
    }
}
