import Foundation

/// Equivalent of JS `Run` resource (operations against
/// `/workflows/:id/...?runId=:runId`). Acquire an instance via
/// `Workflow.createRun(_:)` or construct directly from a known run id.
public struct Run: Sendable {
    public let workflowId: String
    public let runId: String
    let base: BaseResource

    public init(base: BaseResource, workflowId: String, runId: String) {
        self.base = base
        self.workflowId = workflowId
        self.runId = runId
    }

    // MARK: - Cancel

    /// Mirrors JS `cancelRun()` → `POST /workflows/:id/runs/:runId/cancel`.
    /// - Note: Kept for parity with the deprecated JS alias.
    @available(*, deprecated, message: "Use `cancel()` instead")
    public func cancelRun() async throws -> WorkflowMessageResponse {
        try await cancel()
    }

    /// Mirrors JS `cancel()` → `POST /workflows/:id/runs/:runId/cancel`.
    public func cancel() async throws -> WorkflowMessageResponse {
        try await base.request(
            "/workflows/\(workflowId)/runs/\(runId)/cancel",
            method: .POST
        )
    }

    // MARK: - Start

    /// Mirrors JS `start(params)` →
    /// `POST /workflows/:id/start?runId=:runId` (fire-and-forget).
    public func start(_ params: StartParams) async throws -> WorkflowMessageResponse {
        // JS `start` does not forward `resourceId` or `closeOnSuspend`.
        try await base.request(
            "/workflows/\(workflowId)/start",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body(includeResourceId: false, includeCloseOnSuspend: false))
        )
    }

    /// Mirrors JS `startAsync(params)` →
    /// `POST /workflows/:id/start-async?runId=:runId`.
    public func startAsync(_ params: StartParams) async throws -> WorkflowRunResult {
        // JS `startAsync` forwards `resourceId` but not `closeOnSuspend`.
        try await base.request(
            "/workflows/\(workflowId)/start-async",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body(includeResourceId: true, includeCloseOnSuspend: false))
        )
    }

    /// Mirrors JS `stream(params)` →
    /// `POST /workflows/:id/stream?runId=:runId` (record-separator stream).
    public func stream(_ params: StartParams) async throws -> AsyncThrowingStream<JSONValue, Error> {
        // JS `stream` forwards `resourceId` and `closeOnSuspend`.
        try await openRecordStream(
            path: "/workflows/\(workflowId)/stream",
            body: .json(params.body(includeResourceId: true, includeCloseOnSuspend: true))
        )
    }

    /// Mirrors JS `observeStream()` →
    /// `POST /workflows/:id/observe-stream?runId=:runId`.
    public func observeStream() async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openRecordStream(
            path: "/workflows/\(workflowId)/observe-stream",
            body: nil
        )
    }

    // MARK: - Resume

    /// Mirrors JS `resume(params)` →
    /// `POST /workflows/:id/resume?runId=:runId`.
    public func resume(_ params: ResumeParams) async throws -> WorkflowMessageResponse {
        try await base.request(
            "/workflows/\(workflowId)/resume",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    /// Mirrors JS `resumeAsync(params)` →
    /// `POST /workflows/:id/resume-async?runId=:runId`.
    public func resumeAsync(_ params: ResumeParams) async throws -> WorkflowRunResult {
        try await base.request(
            "/workflows/\(workflowId)/resume-async",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    /// Mirrors JS `resumeStream(params)` →
    /// `POST /workflows/:id/resume-stream?runId=:runId` (record-separator stream).
    public func resumeStream(_ params: ResumeParams) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openRecordStream(
            path: "/workflows/\(workflowId)/resume-stream",
            body: .json(params.body())
        )
    }

    // MARK: - Restart

    /// Mirrors JS `restart(params)` →
    /// `POST /workflows/:id/restart?runId=:runId`.
    public func restart(_ params: RestartParams = .init()) async throws -> WorkflowMessageResponse {
        try await base.request(
            "/workflows/\(workflowId)/restart",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    /// Mirrors JS `restartAsync(params?)` →
    /// `POST /workflows/:id/restart-async?runId=:runId`.
    public func restartAsync(_ params: RestartParams = .init()) async throws -> WorkflowRunResult {
        try await base.request(
            "/workflows/\(workflowId)/restart-async",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    // MARK: - Time travel

    /// Mirrors JS `timeTravel(params)` →
    /// `POST /workflows/:id/time-travel?runId=:runId`.
    public func timeTravel(_ params: TimeTravelParams) async throws -> WorkflowMessageResponse {
        try await base.request(
            "/workflows/\(workflowId)/time-travel",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    /// Mirrors JS `timeTravelAsync(params)` →
    /// `POST /workflows/:id/time-travel-async?runId=:runId`.
    public func timeTravelAsync(_ params: TimeTravelParams) async throws -> WorkflowRunResult {
        try await base.request(
            "/workflows/\(workflowId)/time-travel-async",
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: .json(params.body())
        )
    }

    /// Mirrors JS `timeTravelStream(params)` →
    /// `POST /workflows/:id/time-travel-stream?runId=:runId` (record-separator stream).
    public func timeTravelStream(_ params: TimeTravelParams) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openRecordStream(
            path: "/workflows/\(workflowId)/time-travel-stream",
            body: .json(params.body())
        )
    }

    // MARK: - Internal

    private func openRecordStream(
        path: String,
        body: HTTPBody?
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        let response = try await base.streamingRequest(
            path,
            method: .POST,
            query: [URLQueryItem(name: "runId", value: runId)],
            body: body
        )
        return RecordSeparatorJSONDecoder.records(from: response.bytes)
    }
}
