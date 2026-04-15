import Foundation

// MARK: - Pagination info (shared)

/// Mirrors JS `PaginationInfo` from `@mastra/core/storage`. Present in several
/// paginated list responses (scores, traces, …).
public struct PaginationInfo: Sendable, Codable {
    public let total: Int
    public let page: Int
    public let perPage: Int
    public let hasMore: Bool

    public init(total: Int, page: Int, perPage: Int, hasMore: Bool) {
        self.total = total
        self.page = page
        self.perPage = perPage
        self.hasMore = hasMore
    }
}

// MARK: - Score row

/// Mirrors JS `ClientScoreRowData` — a `ScoreRowData` with dates serialized as
/// strings. The inner `scorer`, `input`, `output`, `preprocessStepResult`,
/// `analyzeStepResult`, `extractStepResult`, `runtimeContext`, `entity`,
/// `metadata`, and `additionalContext` are deeply open-shaped so we retain
/// them as `JSONValue`.
public struct ClientScoreRowData: Sendable, Codable {
    public let id: String
    public let scorerId: String?
    public let scorer: JSONValue?
    public let score: Double?
    public let reason: String?
    public let metadata: JSONValue?

    public let entityId: String?
    public let entityType: String?
    public let entity: JSONValue?

    public let runId: String?
    public let traceId: String?
    public let spanId: String?

    public let source: String?
    public let input: JSONValue?
    public let output: JSONValue?

    public let preprocessStepResult: JSONValue?
    public let analyzeStepResult: JSONValue?
    public let extractStepResult: JSONValue?
    public let analyzePrompt: String?
    public let extractPrompt: String?
    public let reasonPrompt: String?
    public let generateScorePrompt: String?
    public let generateReasonPrompt: String?

    public let preprocessPrompt: String?
    public let additionalContext: JSONValue?
    public let runtimeContext: JSONValue?
    public let resourceId: String?
    public let threadId: String?

    public let createdAt: String
    public let updatedAt: String
}

// MARK: - List scores responses (legacy / new)

/// Mirrors JS `ListScoresResponse` (the "old" shape under `client.listScoresBy*`).
public struct ListScoresResponse: Sendable, Codable {
    public let pagination: PaginationInfo
    public let scores: [ClientScoreRowData]

    public init(pagination: PaginationInfo, scores: [ClientScoreRowData]) {
        self.pagination = pagination
        self.scores = scores
    }
}

// MARK: - Save score

/// Mirrors JS `SaveScoreParams = { score: Omit<ScoreRowData, 'id' | 'createdAt' | 'updatedAt'> }`.
public struct SaveScoreParams: Sendable {
    public var score: JSONValue

    public init(score: JSONValue) {
        self.score = score
    }

    func body() -> JSONValue {
        .object(["score": score])
    }
}

/// Mirrors JS `SaveScoreResponse`.
public struct SaveScoreResponse: Sendable, Codable {
    public let score: ClientScoreRowData
    public init(score: ClientScoreRowData) { self.score = score }
}

// MARK: - Scorer discovery

/// Mirrors JS `GetScorerResponse = MastraScorerEntry & { agentIds, agentNames, workflowIds, isRegistered, source }`.
public struct GetScorerResponse: Sendable, Codable {
    public let agentIds: [String]
    public let agentNames: [String]
    public let workflowIds: [String]
    public let isRegistered: Bool
    public let source: Source

    /// `MastraScorerEntry` is an open shape from `@mastra/core` (scorer
    /// metadata, sample config, etc.); held as a JSONValue.
    public let scorer: JSONValue?

    public enum Source: String, Sendable, Codable {
        case code
        case stored
    }

    private enum CodingKeys: String, CodingKey {
        case agentIds, agentNames, workflowIds, isRegistered, source, scorer
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.agentIds = (try? c.decode([String].self, forKey: .agentIds)) ?? []
        self.agentNames = (try? c.decode([String].self, forKey: .agentNames)) ?? []
        self.workflowIds = (try? c.decode([String].self, forKey: .workflowIds)) ?? []
        self.isRegistered = (try? c.decode(Bool.self, forKey: .isRegistered)) ?? false
        self.source = (try? c.decode(Source.self, forKey: .source)) ?? .code
        self.scorer = try? c.decode(JSONValue.self, forKey: .scorer)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(agentIds, forKey: .agentIds)
        try c.encode(agentNames, forKey: .agentNames)
        try c.encode(workflowIds, forKey: .workflowIds)
        try c.encode(isRegistered, forKey: .isRegistered)
        try c.encode(source, forKey: .source)
        if let scorer { try c.encode(scorer, forKey: .scorer) }
    }

    public init(
        agentIds: [String] = [],
        agentNames: [String] = [],
        workflowIds: [String] = [],
        isRegistered: Bool = false,
        source: Source = .code,
        scorer: JSONValue? = nil
    ) {
        self.agentIds = agentIds
        self.agentNames = agentNames
        self.workflowIds = workflowIds
        self.isRegistered = isRegistered
        self.source = source
        self.scorer = scorer
    }
}

// MARK: - Query params for legacy scores list endpoints

/// Mirrors JS `ListScoresByScorerIdParams`.
public struct ListScoresByScorerIdParams: Sendable {
    public var scorerId: String
    public var entityId: String?
    public var entityType: String?
    public var page: Int?
    public var perPage: Int?

    public init(
        scorerId: String,
        entityId: String? = nil,
        entityType: String? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) {
        self.scorerId = scorerId
        self.entityId = entityId
        self.entityType = entityType
        self.page = page
        self.perPage = perPage
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let entityId { items.append(.init(name: "entityId", value: entityId)) }
        if let entityType { items.append(.init(name: "entityType", value: entityType)) }
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        return items
    }
}

/// Mirrors JS `ListScoresByRunIdParams`.
public struct ListScoresByRunIdParams: Sendable {
    public var runId: String
    public var page: Int?
    public var perPage: Int?

    public init(runId: String, page: Int? = nil, perPage: Int? = nil) {
        self.runId = runId
        self.page = page
        self.perPage = perPage
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        return items
    }
}

/// Mirrors JS `ListScoresByEntityIdParams`.
public struct ListScoresByEntityIdParams: Sendable {
    public var entityId: String
    public var entityType: String
    public var page: Int?
    public var perPage: Int?

    public init(entityId: String, entityType: String, page: Int? = nil, perPage: Int? = nil) {
        self.entityId = entityId
        self.entityType = entityType
        self.page = page
        self.perPage = perPage
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        return items
    }
}
