import Foundation

/// Mirrors JS `Processor` from `client-js/src/resources/processor.ts`.
/// Acquire via `MastraClient.processor(id:)`.
public struct Processor: Sendable {
    public let processorId: String
    let base: BaseResource

    init(base: BaseResource, processorId: String) {
        self.base = base
        self.processorId = processorId
    }

    /// Mirrors JS `processor.details(requestContext?)` →
    /// `GET /processors/:processorId`.
    public func details(
        requestContext: RequestContext? = nil
    ) async throws -> GetProcessorDetailResponse {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/processors/\(processorId)",
            query: query
        )
    }

    /// Mirrors JS `processor.execute(params)` →
    /// `POST /processors/:processorId/execute`.
    public func execute(
        _ params: ExecuteProcessorParams
    ) async throws -> ExecuteProcessorResponse {
        try await base.request(
            "/processors/\(processorId)/execute",
            method: .POST,
            body: .json(params.body())
        )
    }
}
