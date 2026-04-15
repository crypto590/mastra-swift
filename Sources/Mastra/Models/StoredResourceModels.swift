import Foundation

// ============================================================================
// Shared list/order types
// ============================================================================

/// Mirrors JS `{ field?: 'createdAt' | 'updatedAt'; direction?: 'ASC' | 'DESC' }`.
/// Used by `listStoredAgents`, `listStoredPromptBlocks`, `listStoredScorers`,
/// `listStoredMCPClients`, `listStoredSkills`.
public struct StoredListOrderBy: Sendable {
    public enum Field: String, Sendable { case createdAt, updatedAt }
    public enum Direction: String, Sendable { case ASC, DESC }

    public var field: Field?
    public var direction: Direction?

    public init(field: Field? = nil, direction: Direction? = nil) {
        self.field = field
        self.direction = direction
    }
}

/// Status filter enum used by the version-resource `details()` methods that
/// accept `status`.
public enum StoredResourceStatus: String, Sendable {
    case draft
    case published
    case archived
}

// ============================================================================
// Stored Agents
// ============================================================================
//
// NOTE: `StoredAgentResponse` is defined in `AgentModels.swift` (used by
// `Agent.clone`) and is reused here unchanged.

/// Mirrors JS `ListStoredAgentsParams`.
public struct ListStoredAgentsParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: StoredListOrderBy?
    public var authorId: String?
    public var metadata: JSONValue?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: StoredListOrderBy? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.authorId = authorId
        self.metadata = metadata
    }

    /// Builds the query items exactly like JS `listStoredAgents` does:
    /// `orderBy[field]`, `orderBy[direction]`, `metadata` JSON-stringified.
    var queryItems: [URLQueryItem] {
        StoredResourceQuery.common(
            page: page,
            perPage: perPage,
            orderBy: orderBy,
            authorId: authorId,
            metadata: metadata
        )
    }
}

/// Mirrors JS `ListStoredAgentsResponse`.
public struct ListStoredAgentsResponse: Sendable, Codable {
    public let agents: [StoredAgentResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

/// Mirrors JS `CreateStoredAgentParams`. The wire surface is genuinely open
/// (many `ConditionalField<...>` types), so beyond the required scalars we
/// model the rest as `JSONValue` passthroughs.
public struct CreateStoredAgentParams: Sendable {
    public var id: String?
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String
    public var description: String?
    public var instructions: JSONValue
    public var model: JSONValue
    public var tools: JSONValue?
    public var defaultOptions: JSONValue?
    public var workflows: JSONValue?
    public var agents: JSONValue?
    public var integrationTools: JSONValue?
    public var mcpClients: JSONValue?
    public var inputProcessors: JSONValue?
    public var outputProcessors: JSONValue?
    public var memory: JSONValue?
    public var scorers: JSONValue?
    public var skills: JSONValue?
    public var workspace: JSONValue?
    public var requestContextSchema: JSONValue?

    public init(
        id: String? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String,
        description: String? = nil,
        instructions: JSONValue,
        model: JSONValue,
        tools: JSONValue? = nil,
        defaultOptions: JSONValue? = nil,
        workflows: JSONValue? = nil,
        agents: JSONValue? = nil,
        integrationTools: JSONValue? = nil,
        mcpClients: JSONValue? = nil,
        inputProcessors: JSONValue? = nil,
        outputProcessors: JSONValue? = nil,
        memory: JSONValue? = nil,
        scorers: JSONValue? = nil,
        skills: JSONValue? = nil,
        workspace: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.instructions = instructions
        self.model = model
        self.tools = tools
        self.defaultOptions = defaultOptions
        self.workflows = workflows
        self.agents = agents
        self.integrationTools = integrationTools
        self.mcpClients = mcpClients
        self.inputProcessors = inputProcessors
        self.outputProcessors = outputProcessors
        self.memory = memory
        self.scorers = scorers
        self.skills = skills
        self.workspace = workspace
        self.requestContextSchema = requestContextSchema
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let id { obj["id"] = .string(id) }
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        obj["name"] = .string(name)
        if let description { obj["description"] = .string(description) }
        obj["instructions"] = instructions
        obj["model"] = model
        if let tools { obj["tools"] = tools }
        if let defaultOptions { obj["defaultOptions"] = defaultOptions }
        if let workflows { obj["workflows"] = workflows }
        if let agents { obj["agents"] = agents }
        if let integrationTools { obj["integrationTools"] = integrationTools }
        if let mcpClients { obj["mcpClients"] = mcpClients }
        if let inputProcessors { obj["inputProcessors"] = inputProcessors }
        if let outputProcessors { obj["outputProcessors"] = outputProcessors }
        if let memory { obj["memory"] = memory }
        if let scorers { obj["scorers"] = scorers }
        if let skills { obj["skills"] = skills }
        if let workspace { obj["workspace"] = workspace }
        if let requestContextSchema { obj["requestContextSchema"] = requestContextSchema }
        return .object(obj)
    }
}

/// Mirrors JS `UpdateStoredAgentParams` (all fields optional; adds
/// `changeMessage` for the auto-created version).
public struct UpdateStoredAgentParams: Sendable {
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String?
    public var description: String?
    public var instructions: JSONValue?
    public var model: JSONValue?
    public var tools: JSONValue?
    public var defaultOptions: JSONValue?
    public var workflows: JSONValue?
    public var agents: JSONValue?
    public var integrationTools: JSONValue?
    public var mcpClients: JSONValue?
    public var inputProcessors: JSONValue?
    public var outputProcessors: JSONValue?
    public var memory: JSONValue?
    public var scorers: JSONValue?
    public var skills: JSONValue?
    public var workspace: JSONValue?
    public var requestContextSchema: JSONValue?
    public var changeMessage: String?

    public init(
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String? = nil,
        description: String? = nil,
        instructions: JSONValue? = nil,
        model: JSONValue? = nil,
        tools: JSONValue? = nil,
        defaultOptions: JSONValue? = nil,
        workflows: JSONValue? = nil,
        agents: JSONValue? = nil,
        integrationTools: JSONValue? = nil,
        mcpClients: JSONValue? = nil,
        inputProcessors: JSONValue? = nil,
        outputProcessors: JSONValue? = nil,
        memory: JSONValue? = nil,
        scorers: JSONValue? = nil,
        skills: JSONValue? = nil,
        workspace: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil,
        changeMessage: String? = nil
    ) {
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.instructions = instructions
        self.model = model
        self.tools = tools
        self.defaultOptions = defaultOptions
        self.workflows = workflows
        self.agents = agents
        self.integrationTools = integrationTools
        self.mcpClients = mcpClients
        self.inputProcessors = inputProcessors
        self.outputProcessors = outputProcessors
        self.memory = memory
        self.scorers = scorers
        self.skills = skills
        self.workspace = workspace
        self.requestContextSchema = requestContextSchema
        self.changeMessage = changeMessage
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        if let name { obj["name"] = .string(name) }
        if let description { obj["description"] = .string(description) }
        if let instructions { obj["instructions"] = instructions }
        if let model { obj["model"] = model }
        if let tools { obj["tools"] = tools }
        if let defaultOptions { obj["defaultOptions"] = defaultOptions }
        if let workflows { obj["workflows"] = workflows }
        if let agents { obj["agents"] = agents }
        if let integrationTools { obj["integrationTools"] = integrationTools }
        if let mcpClients { obj["mcpClients"] = mcpClients }
        if let inputProcessors { obj["inputProcessors"] = inputProcessors }
        if let outputProcessors { obj["outputProcessors"] = outputProcessors }
        if let memory { obj["memory"] = memory }
        if let scorers { obj["scorers"] = scorers }
        if let skills { obj["skills"] = skills }
        if let workspace { obj["workspace"] = workspace }
        if let requestContextSchema { obj["requestContextSchema"] = requestContextSchema }
        if let changeMessage { obj["changeMessage"] = .string(changeMessage) }
        return .object(obj)
    }
}

public struct DeleteStoredAgentResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

/// Mirrors JS `CreateAgentVersionParams` (the stored-agent POST body).
public struct CreateStoredAgentVersionParams: Sendable, Codable {
    public var changeMessage: String?

    public init(changeMessage: String? = nil) {
        self.changeMessage = changeMessage
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let changeMessage { obj["changeMessage"] = .string(changeMessage) }
        return .object(obj)
    }
}

// ============================================================================
// Stored Prompt Blocks
// ============================================================================

/// Mirrors JS `StoredPromptBlockResponse`.
public struct StoredPromptBlockResponse: Sendable, Codable {
    public let id: String
    public let status: String
    public let activeVersionId: String?
    public let hasDraft: Bool?
    public let authorId: String?
    public let metadata: JSONValue?
    public let createdAt: String
    public let updatedAt: String
    public let name: String
    public let description: String?
    public let content: String
    public let rules: JSONValue?
    public let requestContextSchema: JSONValue?
}

public struct ListStoredPromptBlocksParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: StoredListOrderBy?
    public var status: StoredResourceStatus?
    public var authorId: String?
    public var metadata: JSONValue?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: StoredListOrderBy? = nil,
        status: StoredResourceStatus? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.status = status
        self.authorId = authorId
        self.metadata = metadata
    }

    var queryItems: [URLQueryItem] {
        var items = StoredResourceQuery.common(
            page: page, perPage: perPage, orderBy: orderBy,
            authorId: authorId, metadata: metadata
        )
        if let status {
            items.append(.init(name: "status", value: status.rawValue))
        }
        return items
    }
}

public struct ListStoredPromptBlocksResponse: Sendable, Codable {
    public let promptBlocks: [StoredPromptBlockResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreateStoredPromptBlockParams: Sendable {
    public var id: String?
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String
    public var description: String?
    public var content: String
    public var rules: JSONValue?
    public var requestContextSchema: JSONValue?

    public init(
        id: String? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String,
        description: String? = nil,
        content: String,
        rules: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.content = content
        self.rules = rules
        self.requestContextSchema = requestContextSchema
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let id { obj["id"] = .string(id) }
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        obj["name"] = .string(name)
        if let description { obj["description"] = .string(description) }
        obj["content"] = .string(content)
        if let rules { obj["rules"] = rules }
        if let requestContextSchema { obj["requestContextSchema"] = requestContextSchema }
        return .object(obj)
    }
}

public struct UpdateStoredPromptBlockParams: Sendable {
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String?
    public var description: String?
    public var content: String?
    public var rules: JSONValue?
    public var requestContextSchema: JSONValue?

    public init(
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String? = nil,
        description: String? = nil,
        content: String? = nil,
        rules: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil
    ) {
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.content = content
        self.rules = rules
        self.requestContextSchema = requestContextSchema
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        if let name { obj["name"] = .string(name) }
        if let description { obj["description"] = .string(description) }
        if let content { obj["content"] = .string(content) }
        if let rules { obj["rules"] = rules }
        if let requestContextSchema { obj["requestContextSchema"] = requestContextSchema }
        return .object(obj)
    }
}

public struct DeleteStoredPromptBlockResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

// MARK: Prompt block versions

public struct PromptBlockVersionResponse: Sendable, Codable {
    public let id: String
    public let blockId: String
    public let versionNumber: Int
    public let name: String
    public let description: String?
    public let content: String
    public let rules: JSONValue?
    public let requestContextSchema: JSONValue?
    public let changedFields: [String]?
    public let changeMessage: String?
    public let createdAt: String
}

public struct ListPromptBlockVersionsParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: OrderBy?
    public var sortDirection: SortDirection?

    public enum OrderBy: String, Sendable { case versionNumber, createdAt }
    public enum SortDirection: String, Sendable { case ASC, DESC }

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: OrderBy? = nil,
        sortDirection: SortDirection? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.sortDirection = sortDirection
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let orderBy { items.append(.init(name: "orderBy", value: orderBy.rawValue)) }
        if let sortDirection { items.append(.init(name: "sortDirection", value: sortDirection.rawValue)) }
        return items
    }
}

public struct ListPromptBlockVersionsResponse: Sendable, Codable {
    public let versions: [PromptBlockVersionResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreatePromptBlockVersionParams: Sendable, Codable {
    public var changeMessage: String?

    public init(changeMessage: String? = nil) { self.changeMessage = changeMessage }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let changeMessage { obj["changeMessage"] = .string(changeMessage) }
        return .object(obj)
    }
}

public struct ActivatePromptBlockVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
    public let activeVersionId: String
}

public struct DeletePromptBlockVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

public struct ComparePromptBlockVersionsResponse: Sendable, Codable {
    public let fromVersion: PromptBlockVersionResponse
    public let toVersion: PromptBlockVersionResponse
    public let diffs: [VersionDiff]

    public struct VersionDiff: Sendable, Codable {
        public let field: String
        public let previousValue: JSONValue?
        public let currentValue: JSONValue?
        public let changeType: String?
    }
}

// ============================================================================
// Stored Scorers
// ============================================================================

/// Mirrors JS `StoredScorerType`.
public enum StoredScorerType: String, Sendable, Codable {
    case llmJudge = "llm-judge"
    case answerRelevancy = "answer-relevancy"
    case answerSimilarity = "answer-similarity"
    case bias
    case contextPrecision = "context-precision"
    case contextRelevance = "context-relevance"
    case faithfulness
    case hallucination
    case noiseSensitivity = "noise-sensitivity"
    case promptAlignment = "prompt-alignment"
    case toolCallAccuracy = "tool-call-accuracy"
    case toxicity
}

public struct StoredScorerResponse: Sendable, Codable {
    public let id: String
    public let status: String
    public let activeVersionId: String?
    public let authorId: String?
    public let metadata: JSONValue?
    public let createdAt: String
    public let updatedAt: String
    public let name: String
    public let description: String?
    public let type: StoredScorerType
    public let model: JSONValue?
    public let instructions: String?
    public let scoreRange: ScoreRange?
    public let presetConfig: JSONValue?
    public let defaultSampling: JSONValue?

    public struct ScoreRange: Sendable, Codable {
        public let min: Double?
        public let max: Double?
    }
}

public struct ListStoredScorersParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: StoredListOrderBy?
    public var authorId: String?
    public var metadata: JSONValue?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: StoredListOrderBy? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.authorId = authorId
        self.metadata = metadata
    }

    var queryItems: [URLQueryItem] {
        StoredResourceQuery.common(
            page: page, perPage: perPage, orderBy: orderBy,
            authorId: authorId, metadata: metadata
        )
    }
}

public struct ListStoredScorersResponse: Sendable, Codable {
    public let scorerDefinitions: [StoredScorerResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreateStoredScorerParams: Sendable {
    public var id: String?
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String
    public var description: String?
    public var type: StoredScorerType
    public var model: JSONValue?
    public var instructions: String?
    public var scoreRange: StoredScorerResponse.ScoreRange?
    public var presetConfig: JSONValue?
    public var defaultSampling: JSONValue?

    public init(
        id: String? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String,
        description: String? = nil,
        type: StoredScorerType,
        model: JSONValue? = nil,
        instructions: String? = nil,
        scoreRange: StoredScorerResponse.ScoreRange? = nil,
        presetConfig: JSONValue? = nil,
        defaultSampling: JSONValue? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.type = type
        self.model = model
        self.instructions = instructions
        self.scoreRange = scoreRange
        self.presetConfig = presetConfig
        self.defaultSampling = defaultSampling
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let id { obj["id"] = .string(id) }
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        obj["name"] = .string(name)
        if let description { obj["description"] = .string(description) }
        obj["type"] = .string(type.rawValue)
        if let model { obj["model"] = model }
        if let instructions { obj["instructions"] = .string(instructions) }
        if let scoreRange { obj["scoreRange"] = StoredResourceQuery.encodeScoreRange(scoreRange) }
        if let presetConfig { obj["presetConfig"] = presetConfig }
        if let defaultSampling { obj["defaultSampling"] = defaultSampling }
        return .object(obj)
    }
}

public struct UpdateStoredScorerParams: Sendable {
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String?
    public var description: String?
    public var type: StoredScorerType?
    public var model: JSONValue?
    public var instructions: String?
    public var scoreRange: StoredScorerResponse.ScoreRange?
    public var presetConfig: JSONValue?
    public var defaultSampling: JSONValue?

    public init(
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String? = nil,
        description: String? = nil,
        type: StoredScorerType? = nil,
        model: JSONValue? = nil,
        instructions: String? = nil,
        scoreRange: StoredScorerResponse.ScoreRange? = nil,
        presetConfig: JSONValue? = nil,
        defaultSampling: JSONValue? = nil
    ) {
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.type = type
        self.model = model
        self.instructions = instructions
        self.scoreRange = scoreRange
        self.presetConfig = presetConfig
        self.defaultSampling = defaultSampling
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        if let name { obj["name"] = .string(name) }
        if let description { obj["description"] = .string(description) }
        if let type { obj["type"] = .string(type.rawValue) }
        if let model { obj["model"] = model }
        if let instructions { obj["instructions"] = .string(instructions) }
        if let scoreRange { obj["scoreRange"] = StoredResourceQuery.encodeScoreRange(scoreRange) }
        if let presetConfig { obj["presetConfig"] = presetConfig }
        if let defaultSampling { obj["defaultSampling"] = defaultSampling }
        return .object(obj)
    }
}

public struct DeleteStoredScorerResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

// MARK: Scorer versions

public struct ScorerVersionResponse: Sendable, Codable {
    public let id: String
    public let scorerDefinitionId: String
    public let versionNumber: Int
    public let name: String
    public let description: String?
    public let type: StoredScorerType
    public let model: JSONValue?
    public let instructions: String?
    public let scoreRange: StoredScorerResponse.ScoreRange?
    public let presetConfig: JSONValue?
    public let defaultSampling: JSONValue?
    public let changedFields: [String]?
    public let changeMessage: String?
    public let createdAt: String
}

public struct ListScorerVersionsParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: OrderBy?
    public var sortDirection: SortDirection?

    public enum OrderBy: String, Sendable { case versionNumber, createdAt }
    public enum SortDirection: String, Sendable { case ASC, DESC }

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: OrderBy? = nil,
        sortDirection: SortDirection? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.sortDirection = sortDirection
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let orderBy { items.append(.init(name: "orderBy", value: orderBy.rawValue)) }
        if let sortDirection { items.append(.init(name: "sortDirection", value: sortDirection.rawValue)) }
        return items
    }
}

public struct ListScorerVersionsResponse: Sendable, Codable {
    public let versions: [ScorerVersionResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreateScorerVersionParams: Sendable, Codable {
    public var changeMessage: String?

    public init(changeMessage: String? = nil) { self.changeMessage = changeMessage }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let changeMessage { obj["changeMessage"] = .string(changeMessage) }
        return .object(obj)
    }
}

public struct ActivateScorerVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
    public let activeVersionId: String
}

public struct DeleteScorerVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

public struct CompareScorerVersionsResponse: Sendable, Codable {
    public let fromVersion: ScorerVersionResponse
    public let toVersion: ScorerVersionResponse
    public let diffs: [VersionDiff]

    public struct VersionDiff: Sendable, Codable {
        public let field: String
        public let previousValue: JSONValue?
        public let currentValue: JSONValue?
        public let changeType: String?
    }
}

// ============================================================================
// Stored MCP Clients
// ============================================================================

public struct StoredMCPServerConfig: Sendable, Codable {
    public enum TransportType: String, Sendable, Codable {
        case stdio
        case http
    }

    public let type: TransportType
    public let command: String?
    public let args: [String]?
    public let env: [String: String]?
    public let url: String?
    public let timeout: Double?

    public init(
        type: TransportType,
        command: String? = nil,
        args: [String]? = nil,
        env: [String: String]? = nil,
        url: String? = nil,
        timeout: Double? = nil
    ) {
        self.type = type
        self.command = command
        self.args = args
        self.env = env
        self.url = url
        self.timeout = timeout
    }
}

public struct StoredMCPClientResponse: Sendable, Codable {
    public let id: String
    public let status: String
    public let activeVersionId: String?
    public let authorId: String?
    public let metadata: JSONValue?
    public let createdAt: String
    public let updatedAt: String
    public let name: String
    public let description: String?
    public let servers: [String: StoredMCPServerConfig]
}

public struct ListStoredMCPClientsParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: StoredListOrderBy?
    public var authorId: String?
    public var metadata: JSONValue?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: StoredListOrderBy? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.authorId = authorId
        self.metadata = metadata
    }

    var queryItems: [URLQueryItem] {
        StoredResourceQuery.common(
            page: page, perPage: perPage, orderBy: orderBy,
            authorId: authorId, metadata: metadata
        )
    }
}

public struct ListStoredMCPClientsResponse: Sendable, Codable {
    public let mcpClients: [StoredMCPClientResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreateStoredMCPClientParams: Sendable {
    public var id: String?
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String
    public var description: String?
    public var servers: [String: StoredMCPServerConfig]

    public init(
        id: String? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String,
        description: String? = nil,
        servers: [String: StoredMCPServerConfig]
    ) {
        self.id = id
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.servers = servers
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let id { obj["id"] = .string(id) }
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        obj["name"] = .string(name)
        if let description { obj["description"] = .string(description) }
        obj["servers"] = StoredResourceQuery.encodeServers(servers)
        return .object(obj)
    }
}

public struct UpdateStoredMCPClientParams: Sendable {
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String?
    public var description: String?
    public var servers: [String: StoredMCPServerConfig]?

    public init(
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String? = nil,
        description: String? = nil,
        servers: [String: StoredMCPServerConfig]? = nil
    ) {
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.servers = servers
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        if let name { obj["name"] = .string(name) }
        if let description { obj["description"] = .string(description) }
        if let servers { obj["servers"] = StoredResourceQuery.encodeServers(servers) }
        return .object(obj)
    }
}

public struct DeleteStoredMCPClientResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

// ============================================================================
// Stored Skills
// ============================================================================

public struct StoredSkillFileNode: Sendable, Codable {
    public enum NodeType: String, Sendable, Codable {
        case file
        case folder
    }

    public let id: String
    public let name: String
    public let type: NodeType
    public let content: String?
    public let children: [StoredSkillFileNode]?

    public init(
        id: String,
        name: String,
        type: NodeType,
        content: String? = nil,
        children: [StoredSkillFileNode]? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.content = content
        self.children = children
    }
}

public struct StoredSkillResponse: Sendable, Codable {
    public let id: String
    public let status: String
    public let authorId: String?
    public let metadata: JSONValue?
    public let createdAt: String
    public let updatedAt: String
    public let name: String
    public let description: String?
    public let instructions: String
    public let license: String?
    public let files: [StoredSkillFileNode]?
}

public struct ListStoredSkillsParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var orderBy: StoredListOrderBy?
    public var authorId: String?
    public var metadata: JSONValue?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: StoredListOrderBy? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.authorId = authorId
        self.metadata = metadata
    }

    var queryItems: [URLQueryItem] {
        StoredResourceQuery.common(
            page: page, perPage: perPage, orderBy: orderBy,
            authorId: authorId, metadata: metadata
        )
    }
}

public struct ListStoredSkillsResponse: Sendable, Codable {
    public let skills: [StoredSkillResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreateStoredSkillParams: Sendable {
    public var id: String?
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String
    public var description: String?
    public var instructions: String
    public var license: String?
    public var files: [StoredSkillFileNode]?

    public init(
        id: String? = nil,
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String,
        description: String? = nil,
        instructions: String,
        license: String? = nil,
        files: [StoredSkillFileNode]? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.instructions = instructions
        self.license = license
        self.files = files
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let id { obj["id"] = .string(id) }
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        obj["name"] = .string(name)
        if let description { obj["description"] = .string(description) }
        obj["instructions"] = .string(instructions)
        if let license { obj["license"] = .string(license) }
        if let files { obj["files"] = StoredResourceQuery.encodeFileNodes(files) }
        return .object(obj)
    }
}

public struct UpdateStoredSkillParams: Sendable {
    public var authorId: String?
    public var metadata: JSONValue?
    public var name: String?
    public var description: String?
    public var instructions: String?
    public var license: String?
    public var files: [StoredSkillFileNode]?

    public init(
        authorId: String? = nil,
        metadata: JSONValue? = nil,
        name: String? = nil,
        description: String? = nil,
        instructions: String? = nil,
        license: String? = nil,
        files: [StoredSkillFileNode]? = nil
    ) {
        self.authorId = authorId
        self.metadata = metadata
        self.name = name
        self.description = description
        self.instructions = instructions
        self.license = license
        self.files = files
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let authorId { obj["authorId"] = .string(authorId) }
        if let metadata { obj["metadata"] = metadata }
        if let name { obj["name"] = .string(name) }
        if let description { obj["description"] = .string(description) }
        if let instructions { obj["instructions"] = .string(instructions) }
        if let license { obj["license"] = .string(license) }
        if let files { obj["files"] = StoredResourceQuery.encodeFileNodes(files) }
        return .object(obj)
    }
}

public struct DeleteStoredSkillResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

// ============================================================================
// Shared query / serialization helpers
// ============================================================================

enum StoredResourceQuery {
    /// Builds the list-endpoint query items that every `list*` method shares:
    /// page, perPage, orderBy[field], orderBy[direction], authorId, metadata.
    static func common(
        page: Int?,
        perPage: Int?,
        orderBy: StoredListOrderBy?,
        authorId: String?,
        metadata: JSONValue?
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let orderBy {
            if let field = orderBy.field {
                items.append(.init(name: "orderBy[field]", value: field.rawValue))
            }
            if let direction = orderBy.direction {
                items.append(.init(name: "orderBy[direction]", value: direction.rawValue))
            }
        }
        if let authorId { items.append(.init(name: "authorId", value: authorId)) }
        if let metadata {
            if let encoded = try? JSONEncoder().encode(metadata),
               let str = String(data: encoded, encoding: .utf8) {
                items.append(.init(name: "metadata", value: str))
            }
        }
        return items
    }

    static func encodeScoreRange(_ range: StoredScorerResponse.ScoreRange) -> JSONValue {
        var obj: JSONObject = [:]
        if let min = range.min { obj["min"] = .double(min) }
        if let max = range.max { obj["max"] = .double(max) }
        return .object(obj)
    }

    static func encodeServers(_ servers: [String: StoredMCPServerConfig]) -> JSONValue {
        var out: JSONObject = [:]
        for (k, v) in servers {
            out[k] = encodeServer(v)
        }
        return .object(out)
    }

    static func encodeServer(_ s: StoredMCPServerConfig) -> JSONValue {
        var obj: JSONObject = ["type": .string(s.type.rawValue)]
        if let command = s.command { obj["command"] = .string(command) }
        if let args = s.args { obj["args"] = .array(args.map { .string($0) }) }
        if let env = s.env {
            var envObj: JSONObject = [:]
            for (k, v) in env { envObj[k] = .string(v) }
            obj["env"] = .object(envObj)
        }
        if let url = s.url { obj["url"] = .string(url) }
        if let timeout = s.timeout { obj["timeout"] = .double(timeout) }
        return .object(obj)
    }

    static func encodeFileNodes(_ nodes: [StoredSkillFileNode]) -> JSONValue {
        .array(nodes.map { encodeFileNode($0) })
    }

    static func encodeFileNode(_ n: StoredSkillFileNode) -> JSONValue {
        var obj: JSONObject = [
            "id": .string(n.id),
            "name": .string(n.name),
            "type": .string(n.type.rawValue),
        ]
        if let content = n.content { obj["content"] = .string(content) }
        if let children = n.children {
            obj["children"] = encodeFileNodes(children)
        }
        return .object(obj)
    }
}
