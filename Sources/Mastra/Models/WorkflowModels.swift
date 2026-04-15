import Foundation

// MARK: - Workflow details

/// Mirrors JS `GetWorkflowResponse`. We keep schema strings opaque and pass the
/// nested step maps through `JSONValue`, matching how the JS client returns
/// open-ended server shapes.
public struct WorkflowInfo: Sendable, Codable {
    public let name: String
    public let description: String?
    public let steps: JSONValue?
    public let allSteps: JSONValue?
    public let stepGraph: JSONValue?
    public let inputSchema: String?
    public let outputSchema: String?
    public let stateSchema: String?
    public let requestContextSchema: String?
    public let isProcessorWorkflow: Bool?
}

public typealias GetWorkflowResponse = WorkflowInfo

// MARK: - Schema helper

/// Mirrors JS `{ inputSchema, outputSchema }` shape returned by `Workflow.getSchema()`.
public struct WorkflowSchemas: Sendable {
    public let inputSchema: JSONValue?
    public let outputSchema: JSONValue?

    public init(inputSchema: JSONValue?, outputSchema: JSONValue?) {
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
    }
}

// MARK: - Runs listing

public enum WorkflowRunStatus: String, Sendable, Codable {
    case running
    case success
    case failed
    case suspended
    case canceled
    case pending
    case waiting
}

/// Mirrors JS `ListWorkflowRunsParams`.
public struct ListWorkflowRunsParams: Sendable {
    public var fromDate: Date?
    public var toDate: Date?
    public var page: Int?
    public var perPage: Int?
    public var resourceId: String?
    public var status: WorkflowRunStatus?
    /// Mirrors JS legacy `offset`.
    public var offset: Int?
    /// Mirrors JS legacy `limit` which accepts `number | false`.
    public var limit: Limit?

    public enum Limit: Sendable {
        case count(Int)
        case disabled
    }

    public init(
        fromDate: Date? = nil,
        toDate: Date? = nil,
        page: Int? = nil,
        perPage: Int? = nil,
        resourceId: String? = nil,
        status: WorkflowRunStatus? = nil,
        offset: Int? = nil,
        limit: Limit? = nil
    ) {
        self.fromDate = fromDate
        self.toDate = toDate
        self.page = page
        self.perPage = perPage
        self.resourceId = resourceId
        self.status = status
        self.offset = offset
        self.limit = limit
    }

    /// Serializes params to query items. Mirrors JS ordering and rules in
    /// `Workflow.runs`.
    func queryItems() -> [URLQueryItem] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var items: [URLQueryItem] = []
        if let fromDate { items.append(.init(name: "fromDate", value: formatter.string(from: fromDate))) }
        if let toDate { items.append(.init(name: "toDate", value: formatter.string(from: toDate))) }
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let limit {
            switch limit {
            case .disabled:
                items.append(.init(name: "limit", value: "false"))
            case .count(let n) where n > 0:
                items.append(.init(name: "limit", value: String(n)))
            default:
                break
            }
        }
        if let offset {
            items.append(.init(name: "offset", value: String(offset)))
        }
        if let resourceId { items.append(.init(name: "resourceId", value: resourceId)) }
        if let status { items.append(.init(name: "status", value: status.rawValue)) }
        return items
    }
}

/// Summary of a single workflow run surfaced by `GET /workflows/:id/runs`.
public struct WorkflowRunSummary: Sendable, Codable {
    public let runId: String
    public let workflowName: String?
    public let resourceId: String?
    public let createdAt: JSONValue?
    public let updatedAt: JSONValue?
    public let status: String?
    public let snapshot: JSONValue?
}

public struct ListWorkflowRunsResponse: Sendable, Codable {
    public let runs: [WorkflowRunSummary]
    public let total: Int?
}

/// Response from `GET /workflows/:id/runs/:runId` — intentionally open-typed
/// because the server composes it from internal workflow-state snapshots.
public typealias GetWorkflowRunByIdResponse = JSONValue

// MARK: - Create run

public struct CreateRunParams: Sendable {
    public var runId: String?
    public var resourceId: String?
    public var disableScorers: Bool?

    public init(
        runId: String? = nil,
        resourceId: String? = nil,
        disableScorers: Bool? = nil
    ) {
        self.runId = runId
        self.resourceId = resourceId
        self.disableScorers = disableScorers
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let resourceId { obj["resourceId"] = .string(resourceId) }
        if let disableScorers { obj["disableScorers"] = .bool(disableScorers) }
        return .object(obj)
    }
}

public struct CreateRunResponse: Sendable, Codable {
    public let runId: String
}

// MARK: - Generic message response

public struct WorkflowMessageResponse: Sendable, Codable {
    public let message: String
}

// MARK: - Run result

/// Mirrors JS `SerializedError` / deserialized `Error` on `WorkflowRunResult`.
public struct WorkflowRunError: Sendable, Codable, Error {
    public let message: String
    public let name: String?
    public let stack: String?

    public init(message: String, name: String? = nil, stack: String? = nil) {
        self.message = message
        self.name = name
        self.stack = stack
    }

    /// Mirrors `getErrorFromUnknown` best-effort extraction used by the JS
    /// client: accepts either a plain string or `{ message, name?, stack? }`.
    public init?(from value: JSONValue?) {
        guard let value else { return nil }
        switch value {
        case .string(let s):
            self.init(message: s)
        case .object(let obj):
            let message = obj["message"]?.stringValue ?? "Unknown workflow error"
            self.init(
                message: message,
                name: obj["name"]?.stringValue,
                stack: obj["stack"]?.stringValue
            )
        default:
            return nil
        }
    }
}

/// Mirrors JS `WorkflowRunResult`. Fields are open-typed because the JS type
/// `WorkflowResult<any, any, any, any>` is intentionally unconstrained.
public struct WorkflowRunResult: Sendable {
    public let status: String?
    public let result: JSONValue?
    public let error: WorkflowRunError?
    public let steps: JSONValue?
    public let payload: JSONValue?
    public let runId: String?
    public let activeStepsPath: JSONValue?
    public let serializedStepGraph: JSONValue?
    /// Any additional fields the server returns, preserved verbatim for callers.
    public let raw: JSONValue

    public init(raw: JSONValue) {
        self.raw = raw
        self.status = raw["status"]?.stringValue
        self.result = raw["result"]
        self.steps = raw["steps"]
        self.payload = raw["payload"]
        self.runId = raw["runId"]?.stringValue
        self.activeStepsPath = raw["activeStepsPath"]
        self.serializedStepGraph = raw["serializedStepGraph"]
        if self.status == "failed" {
            self.error = WorkflowRunError(from: raw["error"])
        } else {
            self.error = nil
        }
    }
}

extension WorkflowRunResult: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(JSONValue.self)
        self.init(raw: raw)
    }
}

// MARK: - Stream chunk

/// Mirrors JS `StreamVNextChunkType`. Parsed lazily from a `JSONValue` so that
/// the open `payload` field remains usable.
public struct StreamVNextChunkType: Sendable {
    public let type: String
    public let payload: JSONValue
    public let runId: String?
    public let from: String?
    public let raw: JSONValue

    public init(raw: JSONValue) {
        self.raw = raw
        self.type = raw["type"]?.stringValue ?? ""
        self.payload = raw["payload"] ?? .null
        self.runId = raw["runId"]?.stringValue
        self.from = raw["from"]?.stringValue
    }
}

// MARK: - Start / Resume params

public struct StartParams: Sendable {
    public var inputData: JSONValue
    public var initialState: JSONValue?
    public var requestContext: RequestContext?
    public var tracingOptions: JSONValue?
    public var resourceId: String?
    public var perStep: Bool?
    public var closeOnSuspend: Bool?

    public init(
        inputData: JSONValue,
        initialState: JSONValue? = nil,
        requestContext: RequestContext? = nil,
        tracingOptions: JSONValue? = nil,
        resourceId: String? = nil,
        perStep: Bool? = nil,
        closeOnSuspend: Bool? = nil
    ) {
        self.inputData = inputData
        self.initialState = initialState
        self.requestContext = requestContext
        self.tracingOptions = tracingOptions
        self.resourceId = resourceId
        self.perStep = perStep
        self.closeOnSuspend = closeOnSuspend
    }

    func body(includeResourceId: Bool, includeCloseOnSuspend: Bool) -> JSONValue {
        var obj: JSONObject = ["inputData": inputData]
        if let initialState { obj["initialState"] = initialState }
        if let requestContext { obj["requestContext"] = .object(requestContext.entries) }
        if let tracingOptions { obj["tracingOptions"] = tracingOptions }
        if includeResourceId, let resourceId { obj["resourceId"] = .string(resourceId) }
        if let perStep { obj["perStep"] = .bool(perStep) }
        if includeCloseOnSuspend, let closeOnSuspend { obj["closeOnSuspend"] = .bool(closeOnSuspend) }
        return .object(obj)
    }
}

public struct ResumeParams: Sendable {
    public var step: [String]?
    public var resumeData: JSONValue?
    public var requestContext: RequestContext?
    public var tracingOptions: JSONValue?
    public var perStep: Bool?

    public init(
        step: [String]? = nil,
        resumeData: JSONValue? = nil,
        requestContext: RequestContext? = nil,
        tracingOptions: JSONValue? = nil,
        perStep: Bool? = nil
    ) {
        self.step = step
        self.resumeData = resumeData
        self.requestContext = requestContext
        self.tracingOptions = tracingOptions
        self.perStep = perStep
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let step {
            obj["step"] = step.count == 1 ? .string(step[0]) : .array(step.map { .string($0) })
        }
        if let resumeData { obj["resumeData"] = resumeData }
        if let requestContext { obj["requestContext"] = .object(requestContext.entries) }
        if let tracingOptions { obj["tracingOptions"] = tracingOptions }
        if let perStep { obj["perStep"] = .bool(perStep) }
        return .object(obj)
    }
}

public struct RestartParams: Sendable {
    public var requestContext: RequestContext?
    public var tracingOptions: JSONValue?

    public init(
        requestContext: RequestContext? = nil,
        tracingOptions: JSONValue? = nil
    ) {
        self.requestContext = requestContext
        self.tracingOptions = tracingOptions
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        if let requestContext { obj["requestContext"] = .object(requestContext.entries) }
        if let tracingOptions { obj["tracingOptions"] = tracingOptions }
        return .object(obj)
    }
}

// MARK: - Time travel

public struct TimeTravelParams: Sendable {
    public var step: [String]
    public var inputData: JSONValue?
    public var resumeData: JSONValue?
    public var initialState: JSONValue?
    public var context: JSONValue?
    public var nestedStepsContext: JSONValue?
    public var requestContext: RequestContext?
    public var tracingOptions: JSONValue?
    public var perStep: Bool?

    public init(
        step: [String],
        inputData: JSONValue? = nil,
        resumeData: JSONValue? = nil,
        initialState: JSONValue? = nil,
        context: JSONValue? = nil,
        nestedStepsContext: JSONValue? = nil,
        requestContext: RequestContext? = nil,
        tracingOptions: JSONValue? = nil,
        perStep: Bool? = nil
    ) {
        self.step = step
        self.inputData = inputData
        self.resumeData = resumeData
        self.initialState = initialState
        self.context = context
        self.nestedStepsContext = nestedStepsContext
        self.requestContext = requestContext
        self.tracingOptions = tracingOptions
        self.perStep = perStep
    }

    func body() -> JSONValue {
        var obj: JSONObject = [:]
        obj["step"] = step.count == 1 ? .string(step[0]) : .array(step.map { .string($0) })
        if let inputData { obj["inputData"] = inputData }
        if let resumeData { obj["resumeData"] = resumeData }
        if let initialState { obj["initialState"] = initialState }
        if let context { obj["context"] = context }
        if let nestedStepsContext { obj["nestedStepsContext"] = nestedStepsContext }
        if let requestContext { obj["requestContext"] = .object(requestContext.entries) }
        if let tracingOptions { obj["tracingOptions"] = tracingOptions }
        if let perStep { obj["perStep"] = .bool(perStep) }
        return .object(obj)
    }
}

// MARK: - RunById options

public struct WorkflowRunByIdOptions: Sendable {
    public var requestContext: RequestContext?
    public var fields: [String]?
    public var withNestedWorkflows: Bool?

    public init(
        requestContext: RequestContext? = nil,
        fields: [String]? = nil,
        withNestedWorkflows: Bool? = nil
    ) {
        self.requestContext = requestContext
        self.fields = fields
        self.withNestedWorkflows = withNestedWorkflows
    }

    func queryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let fields, !fields.isEmpty {
            items.append(.init(name: "fields", value: fields.joined(separator: ",")))
        }
        if let withNestedWorkflows {
            items.append(.init(name: "withNestedWorkflows", value: String(withNestedWorkflows)))
        }
        if let encoded = requestContext?.base64Encoded() {
            items.append(.init(name: "requestContext", value: encoded))
        }
        return items
    }
}
