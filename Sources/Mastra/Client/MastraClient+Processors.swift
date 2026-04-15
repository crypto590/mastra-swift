import Foundation

public extension MastraClient {
    /// Returns a `Processor` handle for the given processor id.
    /// Mirrors JS `client.getProcessor(processorId)`.
    nonisolated func processor(id: String) -> Processor {
        Processor(base: base, processorId: id)
    }

    /// Mirrors JS `client.listProcessors(requestContext?)` → `GET /processors`.
    nonisolated func listProcessors(
        requestContext: RequestContext? = nil
    ) async throws -> [String: GetProcessorResponse] {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return try await base.request("/processors", query: query)
    }
}
