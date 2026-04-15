import Foundation

// MARK: - Thread info

/// Mirrors JS `StorageThreadType` from `@mastra/core/memory`. The shape is
/// server-defined, so open fields like `metadata` are kept as `JSONValue`.
public struct MemoryThreadInfo: Sendable, Codable {
    public let id: String
    public let resourceId: String?
    public let title: String?
    public let metadata: JSONValue?
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        resourceId: String? = nil,
        title: String? = nil,
        metadata: JSONValue? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.resourceId = resourceId
        self.title = title
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Create / update / list threads

/// Mirrors JS `CreateMemoryThreadParams`.
public struct CreateMemoryThreadParams: Sendable {
    public var title: String?
    public var metadata: [String: JSONValue]?
    public var resourceId: String
    public var threadId: String?
    public var agentId: String
    public var requestContext: RequestContext?

    public init(
        resourceId: String,
        agentId: String,
        title: String? = nil,
        metadata: [String: JSONValue]? = nil,
        threadId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.resourceId = resourceId
        self.agentId = agentId
        self.title = title
        self.metadata = metadata
        self.threadId = threadId
        self.requestContext = requestContext
    }

    /// JSON body the server expects. Matches JS `createMemoryThread` which
    /// POSTs the entire params object (including `agentId`, though it is also
    /// present in the query string).
    func body() -> JSONValue {
        var obj: JSONObject = [
            "resourceId": .string(resourceId),
            "agentId": .string(agentId),
        ]
        if let title { obj["title"] = .string(title) }
        if let metadata { obj["metadata"] = .object(metadata) }
        if let threadId { obj["threadId"] = .string(threadId) }
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        return .object(obj)
    }
}

/// Mirrors JS `UpdateMemoryThreadParams`.
public struct UpdateMemoryThreadParams: Sendable {
    public var title: String
    public var metadata: [String: JSONValue]
    public var resourceId: String
    public var requestContext: RequestContext?

    public init(
        title: String,
        metadata: [String: JSONValue],
        resourceId: String,
        requestContext: RequestContext? = nil
    ) {
        self.title = title
        self.metadata = metadata
        self.resourceId = resourceId
        self.requestContext = requestContext
    }

    func body() -> JSONValue {
        var obj: JSONObject = [
            "title": .string(title),
            "metadata": .object(metadata),
            "resourceId": .string(resourceId),
        ]
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        return .object(obj)
    }
}

/// Mirrors JS `ListMemoryThreadsParams`.
public struct ListMemoryThreadsParams: Sendable {
    public var resourceId: String?
    public var metadata: [String: JSONValue]?
    public var agentId: String?
    public var page: Int?
    public var perPage: Int?
    public var orderBy: OrderBy?
    public var sortDirection: SortDirection?
    public var requestContext: RequestContext?

    public enum OrderBy: String, Sendable { case createdAt, updatedAt }
    public enum SortDirection: String, Sendable { case ASC, DESC }

    public init(
        resourceId: String? = nil,
        metadata: [String: JSONValue]? = nil,
        agentId: String? = nil,
        page: Int? = nil,
        perPage: Int? = nil,
        orderBy: OrderBy? = nil,
        sortDirection: SortDirection? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.resourceId = resourceId
        self.metadata = metadata
        self.agentId = agentId
        self.page = page
        self.perPage = perPage
        self.orderBy = orderBy
        self.sortDirection = sortDirection
        self.requestContext = requestContext
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let resourceId {
            items.append(.init(name: "resourceId", value: resourceId))
        }
        if let metadata {
            let data = try? JSONEncoder().encode(JSONValue.object(metadata))
            if let data, let encoded = String(data: data, encoding: .utf8) {
                items.append(.init(name: "metadata", value: encoded))
            }
        }
        if let agentId { items.append(.init(name: "agentId", value: agentId)) }
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let orderBy { items.append(.init(name: "orderBy", value: orderBy.rawValue)) }
        if let sortDirection { items.append(.init(name: "sortDirection", value: sortDirection.rawValue)) }
        return items
    }
}

/// Mirrors JS `ListMemoryThreadsResponse = PaginationInfo & { threads: ... }`.
/// The server may return either the object form or a bare array; the JS
/// client normalizes to this shape so we decode the normalized shape and
/// expose a custom decoder that handles both.
public struct ListMemoryThreadsResponse: Sendable, Codable {
    public let threads: [MemoryThreadInfo]
    public let total: Int?
    public let page: Int?
    public let perPage: Int?
    public let hasMore: Bool?

    public init(
        threads: [MemoryThreadInfo],
        total: Int? = nil,
        page: Int? = nil,
        perPage: Int? = nil,
        hasMore: Bool? = nil
    ) {
        self.threads = threads
        self.total = total
        self.page = page
        self.perPage = perPage
        self.hasMore = hasMore
    }

    private enum CodingKeys: String, CodingKey {
        case threads, total, page, perPage, hasMore
    }

    public init(from decoder: Decoder) throws {
        // Accept either `{ threads, total, ... }` or a bare `[MemoryThreadInfo]`.
        if let single = try? decoder.singleValueContainer(),
           let arr = try? single.decode([MemoryThreadInfo].self) {
            self.threads = arr
            self.total = arr.count
            self.page = 0
            self.perPage = 100
            self.hasMore = false
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.threads = try c.decode([MemoryThreadInfo].self, forKey: .threads)
        self.total = try c.decodeIfPresent(Int.self, forKey: .total)
        self.page = try c.decodeIfPresent(Int.self, forKey: .page)
        self.perPage = try c.decodeIfPresent(Int.self, forKey: .perPage)
        self.hasMore = try c.decodeIfPresent(Bool.self, forKey: .hasMore)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(threads, forKey: .threads)
        try c.encodeIfPresent(total, forKey: .total)
        try c.encodeIfPresent(page, forKey: .page)
        try c.encodeIfPresent(perPage, forKey: .perPage)
        try c.encodeIfPresent(hasMore, forKey: .hasMore)
    }
}

// MARK: - Memory config

public struct GetMemoryConfigParams: Sendable {
    public var agentId: String
    public var requestContext: RequestContext?

    public init(agentId: String, requestContext: RequestContext? = nil) {
        self.agentId = agentId
        self.requestContext = requestContext
    }
}

public struct GetMemoryConfigResponse: Sendable, Codable {
    public let config: MemoryConfig
}

/// Open-typed; the server shape is `MemoryConfig` from `@mastra/core/memory`
/// and can evolve independently.
public typealias MemoryConfig = JSONValue

// MARK: - List thread messages (paginated)

public struct ListMemoryThreadMessagesParams: Sendable {
    public var page: Int?
    public var perPage: Int?
    public var resourceId: String?
    /// `orderBy`, `filter`, `include` are JSON-stringified by the JS client.
    /// We keep them as `JSONValue` for maximum fidelity.
    public var orderBy: JSONValue?
    public var filter: JSONValue?
    public var include: JSONValue?
    public var includeSystemReminders: Bool?
    public var requestContext: RequestContext?

    public init(
        page: Int? = nil,
        perPage: Int? = nil,
        resourceId: String? = nil,
        orderBy: JSONValue? = nil,
        filter: JSONValue? = nil,
        include: JSONValue? = nil,
        includeSystemReminders: Bool? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.resourceId = resourceId
        self.orderBy = orderBy
        self.filter = filter
        self.include = include
        self.includeSystemReminders = includeSystemReminders
        self.requestContext = requestContext
    }
}

/// Mirrors JS `ListMemoryThreadMessagesResponse`. Message content is a union
/// type in the JS client (V1/V2 shapes) so we keep messages as `JSONValue`.
public struct ListMemoryThreadMessagesResponse: Sendable, Codable {
    public let messages: [JSONValue]

    public init(messages: [JSONValue]) { self.messages = messages }
}

// MARK: - Clone

public struct CloneMemoryThreadParams: Sendable {
    public var newThreadId: String?
    public var resourceId: String?
    public var title: String?
    public var metadata: [String: JSONValue]?
    public var options: CloneOptions?
    public var requestContext: RequestContext?

    public struct CloneOptions: Sendable {
        public var messageLimit: Int?
        public var messageFilter: MessageFilter?

        public struct MessageFilter: Sendable {
            public var startDate: Date?
            public var endDate: Date?
            public var messageIds: [String]?

            public init(
                startDate: Date? = nil,
                endDate: Date? = nil,
                messageIds: [String]? = nil
            ) {
                self.startDate = startDate
                self.endDate = endDate
                self.messageIds = messageIds
            }
        }

        public init(messageLimit: Int? = nil, messageFilter: MessageFilter? = nil) {
            self.messageLimit = messageLimit
            self.messageFilter = messageFilter
        }
    }

    public init(
        newThreadId: String? = nil,
        resourceId: String? = nil,
        title: String? = nil,
        metadata: [String: JSONValue]? = nil,
        options: CloneOptions? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.newThreadId = newThreadId
        self.resourceId = resourceId
        self.title = title
        self.metadata = metadata
        self.options = options
        self.requestContext = requestContext
    }

    /// Body shape mirroring JS: `requestContext` is stripped from the body
    /// (it's a query param), everything else is passed through.
    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let newThreadId { obj["newThreadId"] = .string(newThreadId) }
        if let resourceId { obj["resourceId"] = .string(resourceId) }
        if let title { obj["title"] = .string(title) }
        if let metadata { obj["metadata"] = .object(metadata) }
        if let options {
            var opts: JSONObject = [:]
            if let limit = options.messageLimit { opts["messageLimit"] = .int(Int64(limit)) }
            if let filter = options.messageFilter {
                var f: JSONObject = [:]
                if let start = filter.startDate {
                    f["startDate"] = .string(Self.isoString(start))
                }
                if let end = filter.endDate {
                    f["endDate"] = .string(Self.isoString(end))
                }
                if let ids = filter.messageIds {
                    f["messageIds"] = .array(ids.map(JSONValue.string))
                }
                opts["messageFilter"] = .object(f)
            }
            obj["options"] = .object(opts)
        }
        return .object(obj)
    }

    /// ISO 8601 string with fractional seconds, matching JS `Date.toISOString()`.
    static func isoString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}

public struct CloneMemoryThreadResponse: Sendable, Codable {
    public let thread: MemoryThreadInfo
    public let clonedMessages: [JSONValue]
}

// MARK: - Delete messages response

public struct DeleteMessagesResponse: Sendable, Codable {
    public let success: Bool
    public let message: String
}

public struct DeleteThreadResponse: Sendable, Codable {
    public let success: Bool?
    public let message: String?
    public let result: String?
}

// MARK: - Save message to memory

public struct SaveMessageToMemoryParams: Sendable {
    public var messages: [JSONValue]
    public var agentId: String
    public var requestContext: RequestContext?

    public init(
        messages: [JSONValue],
        agentId: String,
        requestContext: RequestContext? = nil
    ) {
        self.messages = messages
        self.agentId = agentId
        self.requestContext = requestContext
    }

    func body() -> JSONValue {
        var obj: JSONObject = [
            "messages": .array(messages),
            "agentId": .string(agentId),
        ]
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        return .object(obj)
    }
}

public struct SaveMessageToMemoryResponse: Sendable, Codable {
    public let messages: [JSONValue]
}

// MARK: - Memory status

public struct GetMemoryStatusResponse: Sendable, Codable {
    public let result: Bool
    public let memoryType: String?
    public let observationalMemory: ObservationalMemoryStatus?

    public struct ObservationalMemoryStatus: Sendable, Codable {
        public let enabled: Bool
        public let hasRecord: Bool?
        public let originType: String?
        public let lastObservedAt: String?
        public let tokenCount: Int?
        public let observationTokenCount: Int?
        public let isObserving: Bool?
        public let isReflecting: Bool?
    }
}

// MARK: - Observational memory

public struct GetObservationalMemoryParams: Sendable {
    public var agentId: String
    public var resourceId: String?
    public var threadId: String?
    public var from: Date?
    public var to: Date?
    public var offset: Int?
    public var limit: Int?
    public var requestContext: RequestContext?

    public init(
        agentId: String,
        resourceId: String? = nil,
        threadId: String? = nil,
        from: Date? = nil,
        to: Date? = nil,
        offset: Int? = nil,
        limit: Int? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.agentId = agentId
        self.resourceId = resourceId
        self.threadId = threadId
        self.from = from
        self.to = to
        self.offset = offset
        self.limit = limit
        self.requestContext = requestContext
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [.init(name: "agentId", value: agentId)]
        if let resourceId { items.append(.init(name: "resourceId", value: resourceId)) }
        if let threadId { items.append(.init(name: "threadId", value: threadId)) }
        if let from {
            items.append(.init(name: "from", value: Self.isoString(from)))
        }
        if let to {
            items.append(.init(name: "to", value: Self.isoString(to)))
        }
        if let offset { items.append(.init(name: "offset", value: String(offset))) }
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        return items
    }

    static func isoString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}

public struct GetObservationalMemoryResponse: Sendable, Codable {
    public let record: JSONValue?
    public let history: [JSONValue]?
}

public struct AwaitBufferStatusParams: Sendable {
    public var agentId: String
    public var resourceId: String?
    public var threadId: String?
    public var requestContext: RequestContext?

    public init(
        agentId: String,
        resourceId: String? = nil,
        threadId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.agentId = agentId
        self.resourceId = resourceId
        self.threadId = threadId
        self.requestContext = requestContext
    }

    func body() -> JSONValue {
        var obj: JSONObject = ["agentId": .string(agentId)]
        if let resourceId { obj["resourceId"] = .string(resourceId) }
        if let threadId { obj["threadId"] = .string(threadId) }
        return .object(obj)
    }
}

public struct AwaitBufferStatusResponse: Sendable, Codable {
    public let record: JSONValue?
}

// MARK: - Working memory

public struct GetWorkingMemoryParams: Sendable {
    public var agentId: String
    public var threadId: String
    public var resourceId: String?
    public var requestContext: RequestContext?

    public init(
        agentId: String,
        threadId: String,
        resourceId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.agentId = agentId
        self.threadId = threadId
        self.resourceId = resourceId
        self.requestContext = requestContext
    }
}

public struct UpdateWorkingMemoryParams: Sendable {
    public var agentId: String
    public var threadId: String
    public var workingMemory: String
    public var resourceId: String?
    public var requestContext: RequestContext?

    public init(
        agentId: String,
        threadId: String,
        workingMemory: String,
        resourceId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.agentId = agentId
        self.threadId = threadId
        self.workingMemory = workingMemory
        self.resourceId = resourceId
        self.requestContext = requestContext
    }

    func body() -> JSONValue {
        var obj: JSONObject = ["workingMemory": .string(workingMemory)]
        if let resourceId { obj["resourceId"] = .string(resourceId) }
        return .object(obj)
    }
}

// MARK: - Search memory

public struct SearchMemoryParams: Sendable {
    public var agentId: String
    public var resourceId: String
    public var threadId: String?
    public var searchQuery: String
    public var memoryConfig: JSONValue?
    public var requestContext: RequestContext?

    public init(
        agentId: String,
        resourceId: String,
        searchQuery: String,
        threadId: String? = nil,
        memoryConfig: JSONValue? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.agentId = agentId
        self.resourceId = resourceId
        self.threadId = threadId
        self.searchQuery = searchQuery
        self.memoryConfig = memoryConfig
        self.requestContext = requestContext
    }
}

public struct MemorySearchResponse: Sendable, Codable {
    public let results: [MemorySearchResult]
    public let count: Int
    public let query: String
    public let searchType: String?
    public let searchScope: String?
}

public struct MemorySearchResult: Sendable, Codable {
    public let id: String
    public let role: String
    public let content: String
    public let createdAt: String
    public let threadId: String?
    public let threadTitle: String?
    public let context: MessageContext?

    public struct MessageContext: Sendable, Codable {
        public let before: [ContextMessage]?
        public let after: [ContextMessage]?

        public struct ContextMessage: Sendable, Codable {
            public let id: String
            public let role: String
            public let content: String
            public let createdAt: String
        }
    }
}
