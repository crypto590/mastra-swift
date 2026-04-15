import Foundation

public extension MastraClient {
    // ========================================================================
    // Stored Agents
    // ========================================================================

    /// Mirrors JS `client.listStoredAgents(params?)` → `GET /stored/agents`.
    nonisolated func listStoredAgents(
        _ params: ListStoredAgentsParams = .init()
    ) async throws -> ListStoredAgentsResponse {
        try await base.request("/stored/agents", query: params.queryItems)
    }

    /// Mirrors JS `client.createStoredAgent(params)` →
    /// `POST /stored/agents`.
    nonisolated func createStoredAgent(
        _ params: CreateStoredAgentParams
    ) async throws -> StoredAgentResponse {
        try await base.request("/stored/agents", method: .POST, body: .json(params.body()))
    }

    /// Mirrors JS `client.getStoredAgent(id)` — returns a `StoredAgent`
    /// handle for further operations.
    nonisolated func storedAgent(id: String) -> StoredAgent {
        StoredAgent(base: base, storedAgentId: id)
    }

    // ========================================================================
    // Stored Prompt Blocks
    // ========================================================================

    nonisolated func listStoredPromptBlocks(
        _ params: ListStoredPromptBlocksParams = .init()
    ) async throws -> ListStoredPromptBlocksResponse {
        try await base.request("/stored/prompt-blocks", query: params.queryItems)
    }

    nonisolated func createStoredPromptBlock(
        _ params: CreateStoredPromptBlockParams
    ) async throws -> StoredPromptBlockResponse {
        try await base.request("/stored/prompt-blocks", method: .POST, body: .json(params.body()))
    }

    nonisolated func storedPromptBlock(id: String) -> StoredPromptBlock {
        StoredPromptBlock(base: base, storedPromptBlockId: id)
    }

    // ========================================================================
    // Stored Scorers
    // ========================================================================

    nonisolated func listStoredScorers(
        _ params: ListStoredScorersParams = .init()
    ) async throws -> ListStoredScorersResponse {
        try await base.request("/stored/scorers", query: params.queryItems)
    }

    nonisolated func createStoredScorer(
        _ params: CreateStoredScorerParams
    ) async throws -> StoredScorerResponse {
        try await base.request("/stored/scorers", method: .POST, body: .json(params.body()))
    }

    nonisolated func storedScorer(id: String) -> StoredScorer {
        StoredScorer(base: base, storedScorerId: id)
    }

    // ========================================================================
    // Stored MCP Clients
    // ========================================================================

    nonisolated func listStoredMCPClients(
        _ params: ListStoredMCPClientsParams = .init()
    ) async throws -> ListStoredMCPClientsResponse {
        try await base.request("/stored/mcp-clients", query: params.queryItems)
    }

    nonisolated func createStoredMCPClient(
        _ params: CreateStoredMCPClientParams
    ) async throws -> StoredMCPClientResponse {
        try await base.request("/stored/mcp-clients", method: .POST, body: .json(params.body()))
    }

    nonisolated func storedMCPClient(id: String) -> StoredMCPClient {
        StoredMCPClient(base: base, storedMCPClientId: id)
    }

    // ========================================================================
    // Stored Skills
    // ========================================================================

    nonisolated func listStoredSkills(
        _ params: ListStoredSkillsParams = .init()
    ) async throws -> ListStoredSkillsResponse {
        try await base.request("/stored/skills", query: params.queryItems)
    }

    nonisolated func createStoredSkill(
        _ params: CreateStoredSkillParams
    ) async throws -> StoredSkillResponse {
        try await base.request("/stored/skills", method: .POST, body: .json(params.body()))
    }

    nonisolated func storedSkill(id: String) -> StoredSkill {
        StoredSkill(base: base, storedSkillId: id)
    }
}
