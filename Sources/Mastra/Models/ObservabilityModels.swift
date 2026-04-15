import Foundation

// MARK: - Span type

/// Mirrors JS `SpanType` from `@mastra/core/observability`. The server's type
/// set is open-ended (span types grow with the core), so we model this as an
/// open RawRepresentable while exposing the known values as statics.
public struct SpanType: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    // Common values seen in the server code (agent_run, workflow_run, tool_call, …).
    public static let agentRun: SpanType = "agent_run"
    public static let workflowRun: SpanType = "workflow_run"
    public static let toolCall: SpanType = "tool_call"
    public static let llmGeneration: SpanType = "llm_generation"
    public static let llmChunk: SpanType = "llm_chunk"
    public static let workflowStep: SpanType = "workflow_step"
    public static let mcpToolCall: SpanType = "mcp_tool_call"
}

// MARK: - Order / pagination primitives shared by the observability API.

/// Mirrors JS `SortDirection`.
public enum SortDirection: String, Sendable, Codable {
    case ASC
    case DESC
}

/// Mirrors JS `OrderBy`.
public struct ObservabilityOrderBy: Sendable, Codable {
    public var field: String
    public var direction: SortDirection

    public init(field: String, direction: SortDirection = .DESC) {
        self.field = field
        self.direction = direction
    }
}

/// Mirrors JS `PaginationArgs` — used by most flattened list queries.
public struct ObservabilityPagination: Sendable, Codable {
    public var page: Int?
    public var perPage: Int?
    public var dateRange: DateRange?

    public init(page: Int? = nil, perPage: Int? = nil, dateRange: DateRange? = nil) {
        self.page = page
        self.perPage = perPage
        self.dateRange = dateRange
    }

    public struct DateRange: Sendable, Codable {
        public var start: Date?
        public var end: Date?
        public init(start: Date? = nil, end: Date? = nil) {
            self.start = start
            self.end = end
        }
    }
}

// MARK: - Records (traces / spans)

/// Mirrors JS `SpanRecord` from `@mastra/core/storage`. Span shapes are deeply
/// open-ended (attributes, events, links, metadata, status, …), so we expose
/// a typed backbone and stash the rest in `raw`.
public struct SpanRecord: Sendable, Codable {
    public let traceId: String
    public let spanId: String
    public let parentSpanId: String?
    public let name: String?
    public let kind: JSONValue?
    public let spanType: SpanType?
    public let startedAt: String?
    public let endedAt: String?
    public let durationMs: Double?
    public let attributes: JSONValue?
    public let metadata: JSONValue?
    public let input: JSONValue?
    public let output: JSONValue?
    public let error: JSONValue?
    public let events: JSONValue?
    public let links: JSONValue?
    public let status: JSONValue?
    public let entityId: String?
    public let entityType: String?
    public let serviceName: String?
    public let environment: String?
    public let tags: JSONValue?
    public let raw: JSONValue

    private static let knownKeys: Set<String> = [
        "traceId", "spanId", "parentSpanId", "name", "kind", "spanType",
        "startedAt", "endedAt", "durationMs", "attributes", "metadata",
        "input", "output", "error", "events", "links", "status",
        "entityId", "entityType", "serviceName", "environment", "tags",
    ]

    private struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        func decode<T: Decodable>(_ name: String, _ type: T.Type) -> T? {
            guard let key = AnyKey(stringValue: name) else { return nil }
            return try? c.decode(T.self, forKey: key)
        }
        self.traceId = decode("traceId", String.self) ?? ""
        self.spanId = decode("spanId", String.self) ?? ""
        self.parentSpanId = decode("parentSpanId", String.self)
        self.name = decode("name", String.self)
        self.kind = decode("kind", JSONValue.self)
        self.spanType = decode("spanType", SpanType.self)
        self.startedAt = decode("startedAt", String.self)
        self.endedAt = decode("endedAt", String.self)
        self.durationMs = decode("durationMs", Double.self)
        self.attributes = decode("attributes", JSONValue.self)
        self.metadata = decode("metadata", JSONValue.self)
        self.input = decode("input", JSONValue.self)
        self.output = decode("output", JSONValue.self)
        self.error = decode("error", JSONValue.self)
        self.events = decode("events", JSONValue.self)
        self.links = decode("links", JSONValue.self)
        self.status = decode("status", JSONValue.self)
        self.entityId = decode("entityId", String.self)
        self.entityType = decode("entityType", String.self)
        self.serviceName = decode("serviceName", String.self)
        self.environment = decode("environment", String.self)
        self.tags = decode("tags", JSONValue.self)

        var obj: JSONObject = [:]
        for key in c.allKeys where !Self.knownKeys.contains(key.stringValue) {
            if let v = try? c.decode(JSONValue.self, forKey: key) {
                obj[key.stringValue] = v
            }
        }
        self.raw = .object(obj)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        func write<T: Encodable>(_ name: String, _ value: T?) throws {
            guard let value, let key = AnyKey(stringValue: name) else { return }
            try c.encode(value, forKey: key)
        }
        try write("traceId", traceId)
        try write("spanId", spanId)
        try write("parentSpanId", parentSpanId)
        try write("name", name)
        try write("kind", kind)
        try write("spanType", spanType)
        try write("startedAt", startedAt)
        try write("endedAt", endedAt)
        try write("durationMs", durationMs)
        try write("attributes", attributes)
        try write("metadata", metadata)
        try write("input", input)
        try write("output", output)
        try write("error", error)
        try write("events", events)
        try write("links", links)
        try write("status", status)
        try write("entityId", entityId)
        try write("entityType", entityType)
        try write("serviceName", serviceName)
        try write("environment", environment)
        try write("tags", tags)
        if case .object(let obj) = raw {
            for (k, v) in obj {
                if let key = AnyKey(stringValue: k) { try c.encode(v, forKey: key) }
            }
        }
    }
}

/// Mirrors JS `TraceRecord` from `@mastra/core/storage`. A trace is a rollup
/// of spans with top-level summary fields.
public struct TraceRecord: Sendable, Codable {
    public let traceId: String
    public let rootSpanId: String?
    public let name: String?
    public let startedAt: String?
    public let endedAt: String?
    public let durationMs: Double?
    public let spans: [SpanRecord]?
    public let entityId: String?
    public let entityType: String?
    public let serviceName: String?
    public let environment: String?
    public let metadata: JSONValue?
    public let attributes: JSONValue?
    public let status: JSONValue?
    public let tags: JSONValue?
    public let raw: JSONValue

    private static let knownKeys: Set<String> = [
        "traceId", "rootSpanId", "name", "startedAt", "endedAt", "durationMs",
        "spans", "entityId", "entityType", "serviceName", "environment",
        "metadata", "attributes", "status", "tags",
    ]

    private struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        func decode<T: Decodable>(_ name: String, _ type: T.Type) -> T? {
            guard let key = AnyKey(stringValue: name) else { return nil }
            return try? c.decode(T.self, forKey: key)
        }
        self.traceId = decode("traceId", String.self) ?? ""
        self.rootSpanId = decode("rootSpanId", String.self)
        self.name = decode("name", String.self)
        self.startedAt = decode("startedAt", String.self)
        self.endedAt = decode("endedAt", String.self)
        self.durationMs = decode("durationMs", Double.self)
        self.spans = decode("spans", [SpanRecord].self)
        self.entityId = decode("entityId", String.self)
        self.entityType = decode("entityType", String.self)
        self.serviceName = decode("serviceName", String.self)
        self.environment = decode("environment", String.self)
        self.metadata = decode("metadata", JSONValue.self)
        self.attributes = decode("attributes", JSONValue.self)
        self.status = decode("status", JSONValue.self)
        self.tags = decode("tags", JSONValue.self)

        var obj: JSONObject = [:]
        for key in c.allKeys where !Self.knownKeys.contains(key.stringValue) {
            if let v = try? c.decode(JSONValue.self, forKey: key) {
                obj[key.stringValue] = v
            }
        }
        self.raw = .object(obj)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        func write<T: Encodable>(_ name: String, _ value: T?) throws {
            guard let value, let key = AnyKey(stringValue: name) else { return }
            try c.encode(value, forKey: key)
        }
        try write("traceId", traceId)
        try write("rootSpanId", rootSpanId)
        try write("name", name)
        try write("startedAt", startedAt)
        try write("endedAt", endedAt)
        try write("durationMs", durationMs)
        try write("spans", spans)
        try write("entityId", entityId)
        try write("entityType", entityType)
        try write("serviceName", serviceName)
        try write("environment", environment)
        try write("metadata", metadata)
        try write("attributes", attributes)
        try write("status", status)
        try write("tags", tags)
        if case .object(let obj) = raw {
            for (k, v) in obj {
                if let key = AnyKey(stringValue: k) { try c.encode(v, forKey: key) }
            }
        }
    }
}

/// Mirrors JS `Trajectory` (structured trace extraction).
public struct Trajectory: Sendable, Codable {
    public let traceId: String?
    public let steps: [JSONValue]
    public let raw: JSONValue

    private struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        let tKey = AnyKey(stringValue: "traceId")!
        let sKey = AnyKey(stringValue: "steps")!
        self.traceId = try? c.decode(String.self, forKey: tKey)
        self.steps = (try? c.decode([JSONValue].self, forKey: sKey)) ?? []
        var obj: JSONObject = [:]
        for key in c.allKeys {
            if let v = try? c.decode(JSONValue.self, forKey: key) {
                obj[key.stringValue] = v
            }
        }
        self.raw = .object(obj)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        if case .object(let obj) = raw {
            for (k, v) in obj {
                if let key = AnyKey(stringValue: k) { try c.encode(v, forKey: key) }
            }
        } else {
            if let traceId, let k = AnyKey(stringValue: "traceId") {
                try c.encode(traceId, forKey: k)
            }
            if let k = AnyKey(stringValue: "steps") { try c.encode(steps, forKey: k) }
        }
    }
}

// MARK: - List traces (new + legacy)

/// Mirrors JS `ListTracesArgs` with the new flattening surface.
public struct ListTracesArgs: Sendable {
    public var filters: Filters?
    public var pagination: ObservabilityPagination?
    public var orderBy: ObservabilityOrderBy?

    public struct Filters: Sendable, Codable {
        public var name: String?
        public var spanType: SpanType?
        public var entityId: String?
        public var entityType: String?
        public var serviceName: String?
        public var environment: String?
        public var status: String?
        public var traceId: String?
        public var spanId: String?
        public var parentSpanId: String?
        public var startedAt: DateFilter?
        public var tags: [String: String]?
        public var attributes: [String: JSONValue]?

        public struct DateFilter: Sendable, Codable {
            public var start: Date?
            public var end: Date?
            public init(start: Date? = nil, end: Date? = nil) {
                self.start = start
                self.end = end
            }
        }

        public init(
            name: String? = nil,
            spanType: SpanType? = nil,
            entityId: String? = nil,
            entityType: String? = nil,
            serviceName: String? = nil,
            environment: String? = nil,
            status: String? = nil,
            traceId: String? = nil,
            spanId: String? = nil,
            parentSpanId: String? = nil,
            startedAt: DateFilter? = nil,
            tags: [String: String]? = nil,
            attributes: [String: JSONValue]? = nil
        ) {
            self.name = name
            self.spanType = spanType
            self.entityId = entityId
            self.entityType = entityType
            self.serviceName = serviceName
            self.environment = environment
            self.status = status
            self.traceId = traceId
            self.spanId = spanId
            self.parentSpanId = parentSpanId
            self.startedAt = startedAt
            self.tags = tags
            self.attributes = attributes
        }
    }

    public init(
        filters: Filters? = nil,
        pagination: ObservabilityPagination? = nil,
        orderBy: ObservabilityOrderBy? = nil
    ) {
        self.filters = filters
        self.pagination = pagination
        self.orderBy = orderBy
    }
}

public struct ListTracesResponse: Sendable, Codable {
    public let pagination: PaginationInfo
    public let traces: [TraceRecord]?
    public let spans: [SpanRecord]?

    public init(
        pagination: PaginationInfo,
        traces: [TraceRecord]? = nil,
        spans: [SpanRecord]? = nil
    ) {
        self.pagination = pagination
        self.traces = traces
        self.spans = spans
    }
}

/// Mirrors JS `LegacyPaginationArgs`.
public struct LegacyPaginationArgs: Sendable {
    public var dateRange: DateRange?
    public var page: Int?
    public var perPage: Int?

    public struct DateRange: Sendable {
        public var start: Date?
        public var end: Date?
        public init(start: Date? = nil, end: Date? = nil) {
            self.start = start
            self.end = end
        }
    }

    public init(dateRange: DateRange? = nil, page: Int? = nil, perPage: Int? = nil) {
        self.dateRange = dateRange
        self.page = page
        self.perPage = perPage
    }
}

/// Mirrors JS `LegacyTracesPaginatedArg`.
public struct LegacyTracesPaginatedArg: Sendable {
    public var filters: Filters?
    public var pagination: LegacyPaginationArgs?

    public struct Filters: Sendable {
        public var name: String?
        public var spanType: SpanType?
        public var entityId: String?
        public var entityType: String?
        public init(
            name: String? = nil,
            spanType: SpanType? = nil,
            entityId: String? = nil,
            entityType: String? = nil
        ) {
            self.name = name
            self.spanType = spanType
            self.entityId = entityId
            self.entityType = entityType
        }
    }

    public init(filters: Filters? = nil, pagination: LegacyPaginationArgs? = nil) {
        self.filters = filters
        self.pagination = pagination
    }
}

/// Mirrors JS `LegacyGetTracesResponse`.
public struct LegacyGetTracesResponse: Sendable, Codable {
    public let spans: [SpanRecord]
    public let pagination: PaginationInfo
    public init(spans: [SpanRecord], pagination: PaginationInfo) {
        self.spans = spans
        self.pagination = pagination
    }
}

// MARK: - Score traces (fire-and-forget)

/// Mirrors JS `ScoreTracesRequest`.
public struct ScoreTracesRequest: Sendable, Codable {
    public var scorerName: String
    public var targets: [Target]

    public struct Target: Sendable, Codable {
        public var traceId: String
        public var spanId: String?
        public init(traceId: String, spanId: String? = nil) {
            self.traceId = traceId
            self.spanId = spanId
        }
    }

    public init(scorerName: String, targets: [Target]) {
        self.scorerName = scorerName
        self.targets = targets
    }
}

/// Mirrors JS `ScoreTracesResponse`.
public struct ScoreTracesResponse: Sendable, Codable {
    public let status: String
    public let message: String
    public init(status: String, message: String) {
        self.status = status
        self.message = message
    }
}

// MARK: - Scores (new observability) list args

/// Mirrors JS `ListScoresArgs`.
public struct ListScoresArgs: Sendable {
    public var filters: [String: JSONValue]?
    public var pagination: ObservabilityPagination?
    public var orderBy: ObservabilityOrderBy?

    public init(
        filters: [String: JSONValue]? = nil,
        pagination: ObservabilityPagination? = nil,
        orderBy: ObservabilityOrderBy? = nil
    ) {
        self.filters = filters
        self.pagination = pagination
        self.orderBy = orderBy
    }
}

// MARK: - List-scores-by-span args

/// Mirrors JS `ListScoresBySpanParams = SpanIds & PaginationArgs`.
public struct ListScoresBySpanParams: Sendable {
    public var traceId: String
    public var spanId: String
    public var page: Int?
    public var perPage: Int?
    public var dateRange: ObservabilityPagination.DateRange?

    public init(
        traceId: String,
        spanId: String,
        page: Int? = nil,
        perPage: Int? = nil,
        dateRange: ObservabilityPagination.DateRange? = nil
    ) {
        self.traceId = traceId
        self.spanId = spanId
        self.page = page
        self.perPage = perPage
        self.dateRange = dateRange
    }
}

// MARK: - Observability list-logs

/// Mirrors JS `ListLogsArgs`. The server-side OLAP query accepts any mix of
/// filter keys (runId, level, serviceName, environment, traceId, etc.), so we
/// model `filters` as an open dictionary. Pagination + orderBy follow the
/// shared flattening shape.
public struct ListLogsArgs: Sendable {
    public var filters: [String: JSONValue]?
    public var pagination: ObservabilityPagination?
    public var orderBy: ObservabilityOrderBy?

    public init(
        filters: [String: JSONValue]? = nil,
        pagination: ObservabilityPagination? = nil,
        orderBy: ObservabilityOrderBy? = nil
    ) {
        self.filters = filters
        self.pagination = pagination
        self.orderBy = orderBy
    }
}

public struct ListLogsResponse: Sendable, Codable {
    public let pagination: PaginationInfo
    public let logs: [BaseLogMessage]
    public init(pagination: PaginationInfo, logs: [BaseLogMessage]) {
        self.pagination = pagination
        self.logs = logs
    }
}

// MARK: - Create score / create feedback

public struct CreateScoreBody: Sendable {
    public var body: JSONValue
    public init(_ body: JSONValue) { self.body = body }
}

public struct CreateScoreResponse: Sendable, Codable {
    public let score: ClientScoreRowData
    public init(score: ClientScoreRowData) { self.score = score }
}

public struct CreateFeedbackBody: Sendable {
    public var body: JSONValue
    public init(_ body: JSONValue) { self.body = body }
}

public struct CreateFeedbackResponse: Sendable, Codable {
    public let feedbackId: String?
    public let feedback: JSONValue?

    private enum CodingKeys: String, CodingKey { case feedbackId, feedback }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.feedbackId = try? c.decode(String.self, forKey: .feedbackId)
        self.feedback = try? c.decode(JSONValue.self, forKey: .feedback)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let feedbackId { try c.encode(feedbackId, forKey: .feedbackId) }
        if let feedback { try c.encode(feedback, forKey: .feedback) }
    }
}

// MARK: - Feedback list

public struct ListFeedbackArgs: Sendable {
    public var filters: [String: JSONValue]?
    public var pagination: ObservabilityPagination?
    public var orderBy: ObservabilityOrderBy?

    public init(
        filters: [String: JSONValue]? = nil,
        pagination: ObservabilityPagination? = nil,
        orderBy: ObservabilityOrderBy? = nil
    ) {
        self.filters = filters
        self.pagination = pagination
        self.orderBy = orderBy
    }
}

public struct ListFeedbackResponse: Sendable, Codable {
    public let pagination: PaginationInfo
    public let feedback: [JSONValue]
    public init(pagination: PaginationInfo, feedback: [JSONValue]) {
        self.pagination = pagination
        self.feedback = feedback
    }
}

// MARK: - OLAP metrics & discovery

/// Shared "OLAP query body" for scores / feedback / metrics aggregate,
/// breakdown, timeseries, and percentiles. The server contract is rich and
/// varies per endpoint, so we pass through an open `JSONValue` body. The
/// typed helpers at the call site construct this body via `.init(_:)`.
public struct ObservabilityQueryBody: Sendable {
    public var body: JSONValue
    public init(_ body: JSONValue) { self.body = body }
}

public struct ObservabilityQueryResponse: Sendable, Codable {
    public let raw: JSONValue

    public init(_ raw: JSONValue) { self.raw = raw }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.raw = try c.decode(JSONValue.self)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }
}

// Endpoint-specific type aliases mirror the JS generic type names so call
// sites feel like the JS client.
public typealias GetScoreAggregateArgs = ObservabilityQueryBody
public typealias GetScoreAggregateResponse = ObservabilityQueryResponse
public typealias GetScoreBreakdownArgs = ObservabilityQueryBody
public typealias GetScoreBreakdownResponse = ObservabilityQueryResponse
public typealias GetScoreTimeSeriesArgs = ObservabilityQueryBody
public typealias GetScoreTimeSeriesResponse = ObservabilityQueryResponse
public typealias GetScorePercentilesArgs = ObservabilityQueryBody
public typealias GetScorePercentilesResponse = ObservabilityQueryResponse

public typealias GetFeedbackAggregateArgs = ObservabilityQueryBody
public typealias GetFeedbackAggregateResponse = ObservabilityQueryResponse
public typealias GetFeedbackBreakdownArgs = ObservabilityQueryBody
public typealias GetFeedbackBreakdownResponse = ObservabilityQueryResponse
public typealias GetFeedbackTimeSeriesArgs = ObservabilityQueryBody
public typealias GetFeedbackTimeSeriesResponse = ObservabilityQueryResponse
public typealias GetFeedbackPercentilesArgs = ObservabilityQueryBody
public typealias GetFeedbackPercentilesResponse = ObservabilityQueryResponse

public typealias GetMetricAggregateArgs = ObservabilityQueryBody
public typealias GetMetricAggregateResponse = ObservabilityQueryResponse
public typealias GetMetricBreakdownArgs = ObservabilityQueryBody
public typealias GetMetricBreakdownResponse = ObservabilityQueryResponse
public typealias GetMetricTimeSeriesArgs = ObservabilityQueryBody
public typealias GetMetricTimeSeriesResponse = ObservabilityQueryResponse
public typealias GetMetricPercentilesArgs = ObservabilityQueryBody
public typealias GetMetricPercentilesResponse = ObservabilityQueryResponse

// MARK: - Discovery params/responses

public struct GetMetricNamesArgs: Sendable {
    public var prefix: String?
    public var limit: Int?
    public init(prefix: String? = nil, limit: Int? = nil) {
        self.prefix = prefix
        self.limit = limit
    }
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let prefix { items.append(.init(name: "prefix", value: prefix)) }
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        return items
    }
}

public struct GetMetricNamesResponse: Sendable, Codable {
    public let names: [String]
    public init(names: [String]) { self.names = names }

    private enum CodingKeys: String, CodingKey { case names }

    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .names) {
            self.names = arr
            return
        }
        // Forward-compat: accept a bare array too.
        let s = try decoder.singleValueContainer()
        self.names = (try? s.decode([String].self)) ?? []
    }
}

public struct GetMetricLabelKeysArgs: Sendable {
    public var metricName: String
    public var prefix: String?
    public var limit: Int?
    public init(metricName: String, prefix: String? = nil, limit: Int? = nil) {
        self.metricName = metricName
        self.prefix = prefix
        self.limit = limit
    }
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [.init(name: "metricName", value: metricName)]
        if let prefix { items.append(.init(name: "prefix", value: prefix)) }
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        return items
    }
}

public struct GetMetricLabelKeysResponse: Sendable, Codable {
    public let keys: [String]
    public init(keys: [String]) { self.keys = keys }
    private enum CodingKeys: String, CodingKey { case keys }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .keys) {
            self.keys = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.keys = (try? s.decode([String].self)) ?? []
    }
}

public struct GetMetricLabelValuesArgs: Sendable {
    public var metricName: String
    public var labelKey: String
    public var prefix: String?
    public var limit: Int?
    public init(metricName: String, labelKey: String, prefix: String? = nil, limit: Int? = nil) {
        self.metricName = metricName
        self.labelKey = labelKey
        self.prefix = prefix
        self.limit = limit
    }
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [
            .init(name: "metricName", value: metricName),
            .init(name: "labelKey", value: labelKey),
        ]
        if let prefix { items.append(.init(name: "prefix", value: prefix)) }
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        return items
    }
}

public struct GetMetricLabelValuesResponse: Sendable, Codable {
    public let values: [String]
    public init(values: [String]) { self.values = values }
    private enum CodingKeys: String, CodingKey { case values }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .values) {
            self.values = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.values = (try? s.decode([String].self)) ?? []
    }
}

public struct GetEntityTypesResponse: Sendable, Codable {
    public let entityTypes: [String]
    public init(entityTypes: [String]) { self.entityTypes = entityTypes }
    private enum CodingKeys: String, CodingKey { case entityTypes }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .entityTypes) {
            self.entityTypes = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.entityTypes = (try? s.decode([String].self)) ?? []
    }
}

public struct GetEntityNamesArgs: Sendable {
    public var entityType: String?
    public var prefix: String?
    public var limit: Int?
    public init(entityType: String? = nil, prefix: String? = nil, limit: Int? = nil) {
        self.entityType = entityType
        self.prefix = prefix
        self.limit = limit
    }
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let entityType { items.append(.init(name: "entityType", value: entityType)) }
        if let prefix { items.append(.init(name: "prefix", value: prefix)) }
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        return items
    }
}

public struct GetEntityNamesResponse: Sendable, Codable {
    public let entityNames: [String]
    public init(entityNames: [String]) { self.entityNames = entityNames }
    private enum CodingKeys: String, CodingKey { case entityNames }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .entityNames) {
            self.entityNames = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.entityNames = (try? s.decode([String].self)) ?? []
    }
}

public struct GetServiceNamesResponse: Sendable, Codable {
    public let serviceNames: [String]
    public init(serviceNames: [String]) { self.serviceNames = serviceNames }
    private enum CodingKeys: String, CodingKey { case serviceNames }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .serviceNames) {
            self.serviceNames = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.serviceNames = (try? s.decode([String].self)) ?? []
    }
}

public struct GetEnvironmentsResponse: Sendable, Codable {
    public let environments: [String]
    public init(environments: [String]) { self.environments = environments }
    private enum CodingKeys: String, CodingKey { case environments }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .environments) {
            self.environments = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.environments = (try? s.decode([String].self)) ?? []
    }
}

public struct GetTagsArgs: Sendable {
    public var entityType: String?
    public var prefix: String?
    public var limit: Int?
    public init(entityType: String? = nil, prefix: String? = nil, limit: Int? = nil) {
        self.entityType = entityType
        self.prefix = prefix
        self.limit = limit
    }
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let entityType { items.append(.init(name: "entityType", value: entityType)) }
        if let prefix { items.append(.init(name: "prefix", value: prefix)) }
        if let limit { items.append(.init(name: "limit", value: String(limit))) }
        return items
    }
}

public struct GetTagsResponse: Sendable, Codable {
    public let tags: [String]
    public init(tags: [String]) { self.tags = tags }
    private enum CodingKeys: String, CodingKey { case tags }
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self),
           let arr = try? c.decode([String].self, forKey: .tags) {
            self.tags = arr; return
        }
        let s = try decoder.singleValueContainer()
        self.tags = (try? s.decode([String].self)) ?? []
    }
}

// MARK: - Query flattening (matches JS `toQueryParams`)

/// Mirrors the JS `toQueryParams(params, flattenKeys)` utility:
///   - primitives → String
///   - Dates → ISO8601
///   - objects/arrays → JSON-stringified
///   - any key listed in `flattenKeys` is recursively merged into the top level.
///
/// Internal; exposed to the resource file via the same module.
enum ObservabilityQuery {
    static func flatten(
        pagination: ObservabilityPagination? = nil,
        orderBy: ObservabilityOrderBy? = nil,
        filters: JSONValue? = nil,
        extras: [String: JSONValue] = [:]
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        // Pagination is flattened.
        if let pagination {
            if let page = pagination.page { items.append(.init(name: "page", value: String(page))) }
            if let perPage = pagination.perPage { items.append(.init(name: "perPage", value: String(perPage))) }
            if let dr = pagination.dateRange {
                let encoded = encodeDateRange(dr)
                if let encoded { items.append(.init(name: "dateRange", value: encoded)) }
            }
        }

        // orderBy flattens to `field` and `direction`.
        if let orderBy {
            items.append(.init(name: "field", value: orderBy.field))
            items.append(.init(name: "direction", value: orderBy.direction.rawValue))
        }

        // Filters flatten via each top-level key of the inner object.
        if case .object(let obj) = filters ?? .null {
            for (k, v) in obj.sorted(by: { $0.key < $1.key }) {
                if let s = serialize(v) {
                    items.append(.init(name: k, value: s))
                }
            }
        }

        for (k, v) in extras.sorted(by: { $0.key < $1.key }) {
            if let s = serialize(v) {
                items.append(.init(name: k, value: s))
            }
        }

        return items
    }

    private static func encodeDateRange(_ dr: ObservabilityPagination.DateRange) -> String? {
        var obj: JSONObject = [:]
        if let start = dr.start {
            obj["start"] = .string(ISO8601Formatter.string(from: start))
        }
        if let end = dr.end {
            obj["end"] = .string(ISO8601Formatter.string(from: end))
        }
        guard !obj.isEmpty else { return nil }
        return serialize(.object(obj))
    }

    private static func serialize(_ v: JSONValue) -> String? {
        switch v {
        case .null: return nil
        case .bool(let b): return String(b)
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .string(let s): return s
        case .array, .object:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.withoutEscapingSlashes]
            guard let data = try? encoder.encode(v) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }
}
