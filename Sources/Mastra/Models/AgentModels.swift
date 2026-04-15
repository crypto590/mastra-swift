import Foundation

// MARK: - Version selector

/// Mirrors JS `AgentVersionIdentifier = { versionId } | { status: 'draft' | 'published' }`.
public enum AgentVersionIdentifier: Sendable, Hashable {
    case versionId(String)
    case status(Status)

    public enum Status: String, Sendable, Hashable {
        case draft
        case published
    }

    /// Query items for URL construction. The server accepts either `versionId`
    /// or `status` depending on which branch is set.
    public var queryItems: [URLQueryItem] {
        switch self {
        case .versionId(let id): return [URLQueryItem(name: "versionId", value: id)]
        case .status(let s): return [URLQueryItem(name: "status", value: s.rawValue)]
        }
    }
}

// MARK: - Agent details response

/// Mirrors JS `GetAgentResponse`. We keep the open-typed surfaces
/// (`tools`, `workflows`, `defaultOptions`) as `JSONValue` because the JS
/// client itself nests other complex unions under them.
public struct GetAgentResponse: Sendable, Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let instructions: JSONValue
    public let tools: JSONValue?
    public let workflows: JSONValue?
    public let agents: JSONValue?
    public let provider: String?
    public let modelId: String?
    public let modelVersion: String?
    public let modelList: JSONValue?
    public let inputProcessors: JSONValue?
    public let outputProcessors: JSONValue?
    public let defaultOptions: JSONValue?
    public let defaultGenerateOptionsLegacy: JSONValue?
    public let defaultStreamOptionsLegacy: JSONValue?
    public let requestContextSchema: String?
    public let source: String?
    public let status: String?
    public let activeVersionId: String?
    public let hasDraft: Bool?
}

public struct ListAgentsResponse: Sendable {
    public let agents: [String: GetAgentResponse]
    public init(_ agents: [String: GetAgentResponse]) { self.agents = agents }
}

// MARK: - Tool response

/// Mirrors JS `GetToolResponse`.
public struct GetToolResponse: Sendable, Codable {
    public let id: String
    public let description: String
    public let inputSchema: String
    public let outputSchema: String
    public let requestContextSchema: String?
}

// MARK: - Model update

public struct UpdateModelParams: Sendable, Codable {
    public let modelId: String
    public let provider: String

    public init(modelId: String, provider: String) {
        self.modelId = modelId
        self.provider = provider
    }
}

public struct UpdateModelInModelListParams: Sendable, Codable {
    public let modelConfigId: String
    public let model: ModelRef?
    public let maxRetries: Int?
    public let enabled: Bool?

    public struct ModelRef: Sendable, Codable {
        public let modelId: String
        public let provider: String
        public init(modelId: String, provider: String) {
            self.modelId = modelId
            self.provider = provider
        }
    }

    public init(
        modelConfigId: String,
        model: ModelRef? = nil,
        maxRetries: Int? = nil,
        enabled: Bool? = nil
    ) {
        self.modelConfigId = modelConfigId
        self.model = model
        self.maxRetries = maxRetries
        self.enabled = enabled
    }
}

public struct ReorderModelListParams: Sendable, Codable {
    public let reorderedModelIds: [String]
    public init(reorderedModelIds: [String]) { self.reorderedModelIds = reorderedModelIds }
}

public struct UpdateModelResponse: Sendable, Codable {
    public let message: String
}

// MARK: - Enhance instructions

public struct EnhanceInstructionsResponse: Sendable, Codable {
    public let explanation: String
    public let new_prompt: String
}

// MARK: - Clone

public struct CloneAgentParams: Sendable {
    public var newId: String?
    public var newName: String?
    public var metadata: [String: JSONValue]?
    public var authorId: String?
    public var requestContext: RequestContext?

    public init(
        newId: String? = nil,
        newName: String? = nil,
        metadata: [String: JSONValue]? = nil,
        authorId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.newId = newId
        self.newName = newName
        self.metadata = metadata
        self.authorId = authorId
        self.requestContext = requestContext
    }

    /// Body payload mirroring JS `clone()` serialization (requestContext is
    /// flattened to its JSON form on the wire).
    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let newId { obj["newId"] = .string(newId) }
        if let newName { obj["newName"] = .string(newName) }
        if let metadata { obj["metadata"] = .object(metadata) }
        if let authorId { obj["authorId"] = .string(authorId) }
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        return .object(obj)
    }
}

public struct StoredAgentResponse: Sendable, Codable {
    public let id: String
    public let status: String
    public let activeVersionId: String?
    public let authorId: String?
    public let metadata: JSONValue?
    public let createdAt: String
    public let updatedAt: String
    public let name: String
    public let description: String?
    public let instructions: JSONValue
    public let model: JSONValue?
    public let tools: JSONValue?
    public let workflows: JSONValue?
    public let agents: JSONValue?
    public let memory: JSONValue?
    public let scorers: JSONValue?
    public let skills: JSONValue?
    public let workspace: JSONValue?
    public let requestContextSchema: JSONValue?
}

// MARK: - Versions

public struct ListAgentVersionsParams: Sendable {
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

public struct AgentVersionResponse: Sendable, Codable {
    public let id: String
    public let agentId: String
    public let versionNumber: Int
    public let name: String
    public let description: String?
    public let instructions: JSONValue
    public let model: JSONValue?
    public let tools: JSONValue?
    public let changedFields: [String]?
    public let changeMessage: String?
    public let createdAt: String
}

public struct ListAgentVersionsResponse: Sendable, Codable {
    public let versions: [AgentVersionResponse]
    public let total: Int
    public let page: Int
    public let hasMore: Bool
}

public struct CreateCodeAgentVersionParams: Sendable, Codable {
    public var instructions: JSONValue?
    public var tools: JSONValue?
    public var changeMessage: String?

    public init(
        instructions: JSONValue? = nil,
        tools: JSONValue? = nil,
        changeMessage: String? = nil
    ) {
        self.instructions = instructions
        self.tools = tools
        self.changeMessage = changeMessage
    }
}

public struct ActivateAgentVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
    public let activeVersionId: String
}

public struct RestoreAgentVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
    public let version: AgentVersionResponse
}

public struct DeleteAgentVersionResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

public struct CompareAgentVersionsResponse: Sendable, Codable {
    public let fromVersion: AgentVersionResponse
    public let toVersion: AgentVersionResponse
    public let diffs: [VersionDiff]

    public struct VersionDiff: Sendable, Codable {
        public let field: String
        public let previousValue: JSONValue?
        public let currentValue: JSONValue?
        public let changeType: String?
    }
}

// MARK: - Model providers

public struct ListAgentsModelProvidersResponse: Sendable, Codable {
    public let providers: [Provider]

    public struct Provider: Sendable, Codable {
        public let id: String
        public let name: String
        public let envVar: String
        public let connected: Bool
        public let docUrl: String?
        public let models: [String]
    }
}

// MARK: - Generate / stream params

/// Generic shape for the `/generate` and `/stream` POST bodies.
/// The JS client uses large union types; we stay intentionally open here.
public struct GenerateParams: Sendable {
    public var messages: JSONValue
    /// Optional memory block: `{ resource, thread }`.
    public var memory: JSONValue?
    public var threadId: String?
    public var resourceId: String?
    public var runId: String?
    public var structuredOutput: JSONValue?
    public var tracingOptions: JSONValue?
    public var requestContext: RequestContext?
    public var clientTools: [ClientTool]?
    /// Arbitrary additional fields merged into the body (e.g. `maxSteps`,
    /// `temperature`, `toolsets`). Matches the open-ended JS API surface.
    public var additionalFields: [String: JSONValue]

    public init(
        messages: JSONValue,
        memory: JSONValue? = nil,
        threadId: String? = nil,
        resourceId: String? = nil,
        runId: String? = nil,
        structuredOutput: JSONValue? = nil,
        tracingOptions: JSONValue? = nil,
        requestContext: RequestContext? = nil,
        clientTools: [ClientTool]? = nil,
        additionalFields: [String: JSONValue] = [:]
    ) {
        self.messages = messages
        self.memory = memory
        self.threadId = threadId
        self.resourceId = resourceId
        self.runId = runId
        self.structuredOutput = structuredOutput
        self.tracingOptions = tracingOptions
        self.requestContext = requestContext
        self.clientTools = clientTools
        self.additionalFields = additionalFields
    }

    /// Serializes to the JSON body the server expects. `clientTools` are
    /// reduced to their wire description; `requestContext` is flattened.
    func body(messagesOverride: JSONValue? = nil) -> JSONValue {
        var obj: JSONObject = additionalFields
        obj["messages"] = messagesOverride ?? messages
        if let memory { obj["memory"] = memory }
        if let threadId { obj["threadId"] = .string(threadId) }
        if let resourceId { obj["resourceId"] = .string(resourceId) }
        if let runId { obj["runId"] = .string(runId) }
        if let structuredOutput { obj["structuredOutput"] = structuredOutput }
        if let tracingOptions { obj["tracingOptions"] = tracingOptions }
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        if let clientTools, !clientTools.isEmpty {
            obj["clientTools"] = clientTools.wireMap()
        }
        return .object(obj)
    }
}
