import Foundation

/// Equivalent of JS `Workflow` resource. Every method maps to an endpoint on
/// the Mastra workflows API; paths match the JS client exactly. Acquire an
/// instance via `MastraClient.workflow(id:)`.
public struct Workflow: Sendable {
    public let workflowId: String
    let base: BaseResource

    init(base: BaseResource, workflowId: String) {
        self.base = base
        self.workflowId = workflowId
    }

    // MARK: - Details

    /// Mirrors JS `workflow.details(requestContext?)` → `GET /workflows/:id`.
    public func details(
        requestContext: RequestContext? = nil
    ) async throws -> WorkflowInfo {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/workflows/\(workflowId)",
            query: query
        )
    }

    // MARK: - Runs

    /// Mirrors JS `workflow.runs(params?, requestContext?)` →
    /// `GET /workflows/:id/runs`.
    public func runs(
        _ params: ListWorkflowRunsParams = .init(),
        requestContext: RequestContext? = nil
    ) async throws -> ListWorkflowRunsResponse {
        var query = params.queryItems()
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/workflows/\(workflowId)/runs",
            query: query
        )
    }

    /// Mirrors JS `workflow.runById(runId, options?)` →
    /// `GET /workflows/:id/runs/:runId`.
    public func runById(
        _ runId: String,
        options: WorkflowRunByIdOptions = .init()
    ) async throws -> GetWorkflowRunByIdResponse {
        try await base.request(
            "/workflows/\(workflowId)/runs/\(runId)",
            query: options.queryItems()
        )
    }

    /// Mirrors JS `workflow.deleteRunById(runId)` →
    /// `DELETE /workflows/:id/runs/:runId`.
    public func deleteRunById(
        _ runId: String
    ) async throws -> WorkflowMessageResponse {
        try await base.request(
            "/workflows/\(workflowId)/runs/\(runId)",
            method: .DELETE
        )
    }

    // MARK: - Schema

    /// Mirrors JS `workflow.getSchema()`. The JS client runs
    /// `parseSuperJsonString` on the raw schema strings; we mirror that by
    /// trying to decode the string as JSON and falling back to the raw
    /// string wrapped in a `JSONValue.string` if parsing fails.
    public func getSchema() async throws -> WorkflowSchemas {
        let details = try await self.details()
        return WorkflowSchemas(
            inputSchema: Self.parseSchemaString(details.inputSchema),
            outputSchema: Self.parseSchemaString(details.outputSchema)
        )
    }

    private static func parseSchemaString(_ value: String?) -> JSONValue? {
        guard let value, !value.isEmpty else { return nil }
        if let data = value.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(JSONValue.self, from: data) {
            return decoded
        }
        return .string(value)
    }

    // MARK: - Create run

    /// Mirrors JS `workflow.createRun(params?)` →
    /// `POST /workflows/:id/create-run`. Returns a `Run` handle.
    public func createRun(
        _ params: CreateRunParams = .init()
    ) async throws -> Run {
        var query: [URLQueryItem] = []
        if let runId = params.runId {
            query.append(.init(name: "runId", value: runId))
        }
        let response: CreateRunResponse = try await base.request(
            "/workflows/\(workflowId)/create-run",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
        return Run(base: base, workflowId: workflowId, runId: response.runId)
    }
}
