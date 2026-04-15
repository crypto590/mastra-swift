import Foundation

public extension MastraClient {
    /// Returns a `Workflow` handle for the given workflow id.
    /// Mirrors JS `client.getWorkflow(workflowId)`.
    nonisolated func workflow(id: String) -> Workflow {
        Workflow(base: base, workflowId: id)
    }

    /// Mirrors JS `client.listWorkflows(requestContext?, partial?)` →
    /// `GET /workflows`. Returns a map from workflow id to `WorkflowInfo`.
    nonisolated func listWorkflows(
        requestContext: RequestContext? = nil,
        partial: Bool = false
    ) async throws -> [String: WorkflowInfo] {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        if partial {
            query.append(.init(name: "partial", value: "true"))
        }
        return try await base.request("/workflows", query: query)
    }
}
