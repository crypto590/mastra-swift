import Foundation

/// Equivalent of JS `AgentBuilder` resource (operations against
/// `/agent-builder/:actionId/*`). Acquire via
/// `MastraClient.agentBuilderAction(id:)`.
public struct AgentBuilder: Sendable {
    public let actionId: String
    let base: BaseResource

    init(base: BaseResource, actionId: String) {
        self.base = base
        self.actionId = actionId
    }

    // MARK: - Action payload shape

    /// Mirrors JS `AgentBuilderActionRequest`.
    public struct ActionRequest: Sendable {
        public var inputData: JSONValue
        public var requestContext: RequestContext?

        public init(inputData: JSONValue, requestContext: RequestContext? = nil) {
            self.inputData = inputData
            self.requestContext = requestContext
        }

        func body() -> JSONValue {
            var obj: JSONObject = ["inputData": inputData]
            if let requestContext {
                obj["requestContext"] = .object(requestContext.entries)
            }
            return .object(obj)
        }
    }

    /// Mirrors JS `AgentBuilderActionResult`.
    public struct ActionResult: Sendable, Codable {
        public let success: Bool
        public let applied: Bool
        public let branchName: String?
        public let message: String
        public let error: String?
        public let errors: [String]?

        public init(
            success: Bool,
            applied: Bool,
            branchName: String? = nil,
            message: String,
            error: String? = nil,
            errors: [String]? = nil
        ) {
            self.success = success
            self.applied = applied
            self.branchName = branchName
            self.message = message
            self.error = error
            self.errors = errors
        }
    }

    // MARK: - Run lifecycle

    public struct CreateRunResponse: Sendable, Codable {
        public let runId: String
    }

    public struct MessageResponse: Sendable, Codable {
        public let message: String
    }

    /// Mirrors JS `createRun({ runId? })` → `POST /agent-builder/:id/create-run`.
    public func createRun(runId: String? = nil) async throws -> CreateRunResponse {
        var query: [URLQueryItem] = []
        if let runId { query.append(.init(name: "runId", value: runId)) }
        return try await base.request(
            "/agent-builder/\(actionId)/create-run",
            method: .POST,
            query: query
        )
    }

    /// Mirrors JS `startAsync(params, runId?)`. Result is decoded directly from
    /// the server response; the JS-side `transformWorkflowResult` mapping is
    /// left to callers because it conflates workflow-status fields that we do
    /// not model as strong types here.
    public func startAsync(
        _ params: ActionRequest,
        runId: String? = nil
    ) async throws -> JSONValue {
        var query: [URLQueryItem] = []
        if let runId { query.append(.init(name: "runId", value: runId)) }
        return try await base.request(
            "/agent-builder/\(actionId)/start-async",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `startActionRun(params, runId)` → `POST /agent-builder/:id/start`.
    public func startActionRun(
        _ params: ActionRequest,
        runId: String
    ) async throws -> MessageResponse {
        try await base.request(
            "/agent-builder/\(actionId)/start",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    // MARK: - Resume

    public struct ResumeParams: Sendable {
        public var step: [String]?
        public var resumeData: JSONValue?
        public var requestContext: RequestContext?

        public init(
            step: [String]? = nil,
            resumeData: JSONValue? = nil,
            requestContext: RequestContext? = nil
        ) {
            self.step = step
            self.resumeData = resumeData
            self.requestContext = requestContext
        }

        func body() -> JSONValue {
            var obj: JSONObject = [:]
            if let step {
                obj["step"] = step.count == 1 ? .string(step[0]) : .array(step.map { .string($0) })
            }
            if let resumeData { obj["resumeData"] = resumeData }
            if let requestContext {
                obj["requestContext"] = .object(requestContext.entries)
            }
            return .object(obj)
        }
    }

    /// Mirrors JS `resume(params, runId)`.
    public func resume(
        _ params: ResumeParams,
        runId: String
    ) async throws -> MessageResponse {
        try await base.request(
            "/agent-builder/\(actionId)/resume",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    /// Mirrors JS `resumeAsync(params, runId)`.
    public func resumeAsync(
        _ params: ResumeParams,
        runId: String
    ) async throws -> JSONValue {
        try await base.request(
            "/agent-builder/\(actionId)/resume-async",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    // MARK: - Streaming endpoints

    /// Mirrors JS `stream(params, runId?)`. Returns a record-separator JSON
    /// stream of `{ type, payload }` objects — we reuse the existing
    /// `RecordSeparatorJSONDecoder`.
    public func stream(
        _ params: ActionRequest,
        runId: String? = nil
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        var query: [URLQueryItem] = []
        if let runId { query.append(.init(name: "runId", value: runId)) }
        return try await openRecordStream(
            path: "/agent-builder/\(actionId)/stream",
            query: query,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `observeStream({ runId })`.
    public func observeStream(runId: String) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openRecordStream(
            path: "/agent-builder/\(actionId)/observe",
            query: [URLQueryItem(name: "runId", value: runId)],
            body: nil
        )
    }

    /// Mirrors JS `observeStreamLegacy({ runId })`.
    public func observeStreamLegacy(runId: String) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openRecordStream(
            path: "/agent-builder/\(actionId)/observe-stream-legacy",
            query: [URLQueryItem(name: "runId", value: runId)],
            body: nil
        )
    }

    public struct ResumeStreamParams: Sendable {
        public var runId: String
        public var step: [String]
        public var resumeData: JSONValue?
        public var requestContext: RequestContext?

        public init(
            runId: String,
            step: [String],
            resumeData: JSONValue? = nil,
            requestContext: RequestContext? = nil
        ) {
            self.runId = runId
            self.step = step
            self.resumeData = resumeData
            self.requestContext = requestContext
        }
    }

    /// Mirrors JS `resumeStream(params)`.
    public func resumeStream(
        _ params: ResumeStreamParams
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        var body: JSONObject = [
            "step": params.step.count == 1
                ? .string(params.step[0])
                : .array(params.step.map { .string($0) }),
        ]
        if let resumeData = params.resumeData { body["resumeData"] = resumeData }
        if let requestContext = params.requestContext {
            body["requestContext"] = .object(requestContext.entries)
        }
        return try await openRecordStream(
            path: "/agent-builder/\(actionId)/resume-stream",
            query: [URLQueryItem(name: "runId", value: params.runId)],
            body: .json(.object(body))
        )
    }

    private func openRecordStream(
        path: String,
        query: [URLQueryItem],
        body: HTTPBody?
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        let response = try await base.streamingRequest(
            path,
            method: .POST,
            query: query,
            body: body
        )
        return RecordSeparatorJSONDecoder.records(from: response.bytes)
    }

    // MARK: - Run introspection

    public struct RunByIdOptions: Sendable {
        public var fields: [String]?
        public var withNestedWorkflows: Bool?

        public init(fields: [String]? = nil, withNestedWorkflows: Bool? = nil) {
            self.fields = fields
            self.withNestedWorkflows = withNestedWorkflows
        }
    }

    /// Mirrors JS `runById(runId, options?)`.
    public func runById(
        _ runId: String,
        options: RunByIdOptions = .init()
    ) async throws -> JSONValue {
        var query: [URLQueryItem] = []
        if let fields = options.fields, !fields.isEmpty {
            query.append(.init(name: "fields", value: fields.joined(separator: ",")))
        }
        if let nested = options.withNestedWorkflows {
            query.append(.init(name: "withNestedWorkflows", value: String(nested)))
        }
        return try await base.request(
            "/agent-builder/\(actionId)/runs/\(runId)",
            query: query
        )
    }

    /// Mirrors JS `details()` → `GET /agent-builder/:id`.
    public func details() async throws -> JSONValue {
        try await base.request("/agent-builder/\(actionId)")
    }

    /// Mirrors JS `runs(params?)` → `GET /agent-builder/:id/runs`.
    public func runs(_ params: RunsParams = .init()) async throws -> JSONValue {
        try await base.request(
            "/agent-builder/\(actionId)/runs",
            query: params.queryItems
        )
    }

    public struct RunsParams: Sendable {
        public var fromDate: Date?
        public var toDate: Date?
        public var page: Int?
        public var perPage: Int?
        public var resourceId: String?

        public init(
            fromDate: Date? = nil,
            toDate: Date? = nil,
            page: Int? = nil,
            perPage: Int? = nil,
            resourceId: String? = nil
        ) {
            self.fromDate = fromDate
            self.toDate = toDate
            self.page = page
            self.perPage = perPage
            self.resourceId = resourceId
        }

        var queryItems: [URLQueryItem] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var items: [URLQueryItem] = []
            if let fromDate { items.append(.init(name: "fromDate", value: formatter.string(from: fromDate))) }
            if let toDate { items.append(.init(name: "toDate", value: formatter.string(from: toDate))) }
            if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
            if let page { items.append(.init(name: "page", value: String(page))) }
            if let resourceId { items.append(.init(name: "resourceId", value: resourceId)) }
            return items
        }
    }

    /// Mirrors JS `cancelRun(runId)`.
    public func cancelRun(_ runId: String) async throws -> MessageResponse {
        try await base.request(
            "/agent-builder/\(actionId)/runs/\(runId)/cancel",
            method: .POST
        )
    }
}
