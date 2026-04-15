import Foundation

/// Mirrors JS `Observability` from `client-js/src/resources/observability.ts`.
/// Acquire an instance via `MastraClient.observability`. All endpoint paths
/// match the JS client exactly.
public struct Observability: Sendable {
    let base: BaseResource

    init(base: BaseResource) {
        self.base = base
    }

    // MARK: - Traces

    /// Mirrors JS `getTrace(traceId)` → `GET /observability/traces/:traceId`.
    public func getTrace(traceId: String) async throws -> TraceRecord {
        try await base.request("/observability/traces/\(traceId)")
    }

    /// Mirrors JS `getTraceTrajectory(traceId)` → `GET /observability/traces/:traceId/trajectory`.
    public func getTraceTrajectory(traceId: String) async throws -> Trajectory {
        try await base.request("/observability/traces/\(traceId)/trajectory")
    }

    /// Mirrors JS `getTraces(params)` (legacy, `@deprecated` in JS).
    public func getTraces(_ params: LegacyTracesPaginatedArg) async throws -> LegacyGetTracesResponse {
        var items: [URLQueryItem] = []
        if let p = params.pagination {
            if let page = p.page { items.append(.init(name: "page", value: String(page))) }
            if let perPage = p.perPage { items.append(.init(name: "perPage", value: String(perPage))) }
            if let dr = p.dateRange {
                var obj: JSONObject = [:]
                if let s = dr.start { obj["start"] = .string(ISO8601Formatter.string(from: s)) }
                if let e = dr.end { obj["end"] = .string(ISO8601Formatter.string(from: e)) }
                if !obj.isEmpty,
                   let data = try? JSONEncoder().encode(JSONValue.object(obj)),
                   let s = String(data: data, encoding: .utf8) {
                    items.append(.init(name: "dateRange", value: s))
                }
            }
        }
        if let f = params.filters {
            if let name = f.name { items.append(.init(name: "name", value: name)) }
            if let spanType = f.spanType { items.append(.init(name: "spanType", value: spanType.rawValue)) }
            if let entityId = f.entityId, let entityType = f.entityType {
                items.append(.init(name: "entityId", value: entityId))
                items.append(.init(name: "entityType", value: entityType))
            }
        }
        return try await base.request("/observability/traces", query: items)
    }

    /// Mirrors JS `listTraces(params)` → `GET /observability/traces` with
    /// flattened `filters` / `pagination` / `orderBy`.
    public func listTraces(_ params: ListTracesArgs = .init()) async throws -> ListTracesResponse {
        var filters: JSONValue?
        if let f = params.filters {
            filters = try encodeAsJSONValue(f)
        }
        let query = ObservabilityQuery.flatten(
            pagination: params.pagination,
            orderBy: params.orderBy,
            filters: filters
        )
        return try await base.request("/observability/traces", query: query)
    }

    /// Mirrors JS `listScoresBySpan(params)` →
    /// `GET /observability/traces/:traceId/:spanId/scores` with pagination in the query string.
    public func listScoresBySpan(_ params: ListScoresBySpanParams) async throws -> ListScoresResponse {
        var items: [URLQueryItem] = []
        if let page = params.page { items.append(.init(name: "page", value: String(page))) }
        if let perPage = params.perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let dr = params.dateRange {
            var obj: JSONObject = [:]
            if let s = dr.start { obj["start"] = .string(ISO8601Formatter.string(from: s)) }
            if let e = dr.end { obj["end"] = .string(ISO8601Formatter.string(from: e)) }
            if !obj.isEmpty,
               let data = try? JSONEncoder().encode(JSONValue.object(obj)),
               let s = String(data: data, encoding: .utf8) {
                items.append(.init(name: "dateRange", value: s))
            }
        }
        let traceEnc = params.traceId.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.traceId
        let spanEnc = params.spanId.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.spanId
        return try await base.request(
            "/observability/traces/\(traceEnc)/\(spanEnc)/scores",
            query: items
        )
    }

    /// Mirrors JS `score(params)` → `POST /observability/traces/score`.
    public func score(_ params: ScoreTracesRequest) async throws -> ScoreTracesResponse {
        let body = try encodeAsJSONValue(params)
        return try await base.request(
            "/observability/traces/score",
            method: .POST,
            body: .json(body)
        )
    }

    // MARK: - Logs

    /// Mirrors JS `listLogs(params)` → `GET /observability/logs` with flattened args.
    public func listLogs(_ params: ListLogsArgs = .init()) async throws -> ListLogsResponse {
        let filters: JSONValue? = params.filters.map { .object($0) }
        let query = ObservabilityQuery.flatten(
            pagination: params.pagination,
            orderBy: params.orderBy,
            filters: filters
        )
        return try await base.request("/observability/logs", query: query)
    }

    // MARK: - Scores (observability storage)

    /// Mirrors JS `listScores(params)` → `GET /observability/scores`.
    public func listScores(_ params: ListScoresArgs = .init()) async throws -> ListScoresResponse {
        let filters: JSONValue? = params.filters.map { .object($0) }
        let query = ObservabilityQuery.flatten(
            pagination: params.pagination,
            orderBy: params.orderBy,
            filters: filters
        )
        return try await base.request("/observability/scores", query: query)
    }

    /// Mirrors JS `createScore(params)` → `POST /observability/scores`.
    public func createScore(_ params: CreateScoreBody) async throws -> CreateScoreResponse {
        try await base.request(
            "/observability/scores",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getScoreAggregate(params)` → `POST /observability/scores/aggregate`.
    public func getScoreAggregate(_ params: GetScoreAggregateArgs) async throws -> GetScoreAggregateResponse {
        try await base.request(
            "/observability/scores/aggregate",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getScoreBreakdown(params)` → `POST /observability/scores/breakdown`.
    public func getScoreBreakdown(_ params: GetScoreBreakdownArgs) async throws -> GetScoreBreakdownResponse {
        try await base.request(
            "/observability/scores/breakdown",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getScoreTimeSeries(params)` → `POST /observability/scores/timeseries`.
    public func getScoreTimeSeries(_ params: GetScoreTimeSeriesArgs) async throws -> GetScoreTimeSeriesResponse {
        try await base.request(
            "/observability/scores/timeseries",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getScorePercentiles(params)` → `POST /observability/scores/percentiles`.
    public func getScorePercentiles(_ params: GetScorePercentilesArgs) async throws -> GetScorePercentilesResponse {
        try await base.request(
            "/observability/scores/percentiles",
            method: .POST,
            body: .json(params.body)
        )
    }

    // MARK: - Feedback

    /// Mirrors JS `listFeedback(params)` → `GET /observability/feedback`.
    public func listFeedback(_ params: ListFeedbackArgs = .init()) async throws -> ListFeedbackResponse {
        let filters: JSONValue? = params.filters.map { .object($0) }
        let query = ObservabilityQuery.flatten(
            pagination: params.pagination,
            orderBy: params.orderBy,
            filters: filters
        )
        return try await base.request("/observability/feedback", query: query)
    }

    /// Mirrors JS `createFeedback(params)` → `POST /observability/feedback`.
    public func createFeedback(_ params: CreateFeedbackBody) async throws -> CreateFeedbackResponse {
        try await base.request(
            "/observability/feedback",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getFeedbackAggregate(params)` → `POST /observability/feedback/aggregate`.
    public func getFeedbackAggregate(_ params: GetFeedbackAggregateArgs) async throws -> GetFeedbackAggregateResponse {
        try await base.request(
            "/observability/feedback/aggregate",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getFeedbackBreakdown(params)` → `POST /observability/feedback/breakdown`.
    public func getFeedbackBreakdown(_ params: GetFeedbackBreakdownArgs) async throws -> GetFeedbackBreakdownResponse {
        try await base.request(
            "/observability/feedback/breakdown",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getFeedbackTimeSeries(params)` → `POST /observability/feedback/timeseries`.
    public func getFeedbackTimeSeries(_ params: GetFeedbackTimeSeriesArgs) async throws -> GetFeedbackTimeSeriesResponse {
        try await base.request(
            "/observability/feedback/timeseries",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getFeedbackPercentiles(params)` → `POST /observability/feedback/percentiles`.
    public func getFeedbackPercentiles(_ params: GetFeedbackPercentilesArgs) async throws -> GetFeedbackPercentilesResponse {
        try await base.request(
            "/observability/feedback/percentiles",
            method: .POST,
            body: .json(params.body)
        )
    }

    // MARK: - Metrics OLAP

    /// Mirrors JS `getMetricAggregate(params)` → `POST /observability/metrics/aggregate`.
    public func getMetricAggregate(_ params: GetMetricAggregateArgs) async throws -> GetMetricAggregateResponse {
        try await base.request(
            "/observability/metrics/aggregate",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getMetricBreakdown(params)` → `POST /observability/metrics/breakdown`.
    public func getMetricBreakdown(_ params: GetMetricBreakdownArgs) async throws -> GetMetricBreakdownResponse {
        try await base.request(
            "/observability/metrics/breakdown",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getMetricTimeSeries(params)` → `POST /observability/metrics/timeseries`.
    public func getMetricTimeSeries(_ params: GetMetricTimeSeriesArgs) async throws -> GetMetricTimeSeriesResponse {
        try await base.request(
            "/observability/metrics/timeseries",
            method: .POST,
            body: .json(params.body)
        )
    }

    /// Mirrors JS `getMetricPercentiles(params)` → `POST /observability/metrics/percentiles`.
    public func getMetricPercentiles(_ params: GetMetricPercentilesArgs) async throws -> GetMetricPercentilesResponse {
        try await base.request(
            "/observability/metrics/percentiles",
            method: .POST,
            body: .json(params.body)
        )
    }

    // MARK: - Discovery

    /// Mirrors JS `getMetricNames(params)` → `GET /observability/discovery/metric-names`.
    public func getMetricNames(_ params: GetMetricNamesArgs = .init()) async throws -> GetMetricNamesResponse {
        try await base.request(
            "/observability/discovery/metric-names",
            query: params.queryItems
        )
    }

    /// Mirrors JS `getMetricLabelKeys(params)` → `GET /observability/discovery/metric-label-keys`.
    public func getMetricLabelKeys(_ params: GetMetricLabelKeysArgs) async throws -> GetMetricLabelKeysResponse {
        try await base.request(
            "/observability/discovery/metric-label-keys",
            query: params.queryItems
        )
    }

    /// Mirrors JS `getMetricLabelValues(params)` → `GET /observability/discovery/metric-label-values`.
    public func getMetricLabelValues(_ params: GetMetricLabelValuesArgs) async throws -> GetMetricLabelValuesResponse {
        try await base.request(
            "/observability/discovery/metric-label-values",
            query: params.queryItems
        )
    }

    /// Mirrors JS `getEntityTypes()` → `GET /observability/discovery/entity-types`.
    public func getEntityTypes() async throws -> GetEntityTypesResponse {
        try await base.request("/observability/discovery/entity-types")
    }

    /// Mirrors JS `getEntityNames(params)` → `GET /observability/discovery/entity-names`.
    public func getEntityNames(_ params: GetEntityNamesArgs = .init()) async throws -> GetEntityNamesResponse {
        try await base.request(
            "/observability/discovery/entity-names",
            query: params.queryItems
        )
    }

    /// Mirrors JS `getServiceNames()` → `GET /observability/discovery/service-names`.
    public func getServiceNames() async throws -> GetServiceNamesResponse {
        try await base.request("/observability/discovery/service-names")
    }

    /// Mirrors JS `getEnvironments()` → `GET /observability/discovery/environments`.
    public func getEnvironments() async throws -> GetEnvironmentsResponse {
        try await base.request("/observability/discovery/environments")
    }

    /// Mirrors JS `getTags(params)` → `GET /observability/discovery/tags`.
    public func getTags(_ params: GetTagsArgs = .init()) async throws -> GetTagsResponse {
        try await base.request(
            "/observability/discovery/tags",
            query: params.queryItems
        )
    }

    // MARK: - Helpers

    private func encodeAsJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }
}
