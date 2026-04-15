import Foundation

/// Equivalent of JS `Responses` resource. Methods map one-to-one to the JS
/// client: `create`, `stream`, `retrieve`, `delete`. Paths match `/v1/responses`.
///
/// Acquire an instance via `MastraClient.responses`.
public struct Responses: Sendable {
    let base: BaseResource

    init(base: BaseResource) {
        self.base = base
    }

    // MARK: - create (non-streaming)

    /// Mirrors JS `responses.create(params)` when `stream` is false/omitted.
    /// Attaches the derived `output_text` field from message output items,
    /// matching the JS `attachOutputText` behavior.
    public func create(_ params: CreateResponseParams) async throws -> ResponsesResponse {
        let query = Self.requestContextQuery(params.requestContext)
        let raw: JSONValue = try await base.request(
            "/v1/responses",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
        let hydrated = attachOutputText(raw)
        let data = try JSONEncoder().encode(hydrated)
        return try JSONDecoder().decode(ResponsesResponse.self, from: data)
    }

    // MARK: - stream

    /// Mirrors JS `responses.stream(params)` — a thin helper over `create`
    /// that forces `stream: true` and yields an async sequence of typed
    /// `ResponseEvent`s.
    public func stream(_ params: CreateResponseParams) async throws -> AsyncThrowingStream<ResponseEvent, Error> {
        let query = Self.requestContextQuery(params.requestContext)
        let response = try await base.streamingRequest(
            "/v1/responses",
            method: .POST,
            query: query,
            body: .json(params.body(stream: true))
        )
        return Self.decodeEvents(from: response.bytes)
    }

    // MARK: - retrieve

    /// Mirrors JS `responses.retrieve(id, requestContext?)` → `GET /v1/responses/:id`.
    public func retrieve(
        _ responseId: String,
        requestContext: RequestContext? = nil
    ) async throws -> ResponsesResponse {
        let raw: JSONValue = try await base.request(
            "/v1/responses/\(percentEncoded(responseId))",
            method: .GET,
            query: Self.requestContextQuery(requestContext)
        )
        let hydrated = attachOutputText(raw)
        let data = try JSONEncoder().encode(hydrated)
        return try JSONDecoder().decode(ResponsesResponse.self, from: data)
    }

    // MARK: - delete

    /// Mirrors JS `responses.delete(id, requestContext?)` → `DELETE /v1/responses/:id`.
    @discardableResult
    public func delete(
        _ responseId: String,
        requestContext: RequestContext? = nil
    ) async throws -> ResponsesDeleteResponse {
        try await base.request(
            "/v1/responses/\(percentEncoded(responseId))",
            method: .DELETE,
            query: Self.requestContextQuery(requestContext)
        )
    }

    // MARK: - Helpers

    /// Mirrors JS `requestContextQueryString` — only the per-call context
    /// travels in the query here; the global context is already injected
    /// by `BaseResource.buildRequest`.
    private static func requestContextQuery(_ context: RequestContext?) -> [URLQueryItem] {
        guard let context, let encoded = context.base64Encoded() else { return [] }
        return [URLQueryItem(name: "requestContext", value: encoded)]
    }

    /// Matches JS `encodeURIComponent` for path segments.
    private func percentEncoded(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? segment
    }

    /// Decodes the SSE byte stream into typed `ResponseEvent`s, mirroring
    /// the JS `ResponsesStream` iterator (including `[DONE]` sentinel and
    /// `hydrateStreamEvent`).
    static func decodeEvents<S: AsyncSequence & Sendable>(
        from bytes: S
    ) -> AsyncThrowingStream<ResponseEvent, Error> where S.Element == UInt8 {
        let sseStream = SSEDecoder.events(from: bytes)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await event in sseStream {
                        let data = event.data
                        if data.isEmpty || data == "[DONE]" { continue }
                        guard let payload = data.data(using: .utf8),
                              let json = try? JSONDecoder().decode(JSONValue.self, from: payload),
                              let decoded = ResponseEvent.from(json: json)
                        else { continue }
                        continuation.yield(decoded)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
