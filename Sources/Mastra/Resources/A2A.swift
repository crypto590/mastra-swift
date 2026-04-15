import Foundation

/// Equivalent of JS `A2A` resource. Wraps the Agent-to-Agent (A2A) protocol
/// endpoints for a specific agent id. Method names and paths mirror the JS
/// client (`resources/a2a.ts`) exactly.
///
/// Acquire an instance via `MastraClient.a2a(agentId:)`.
public struct A2A: Sendable {
    public let agentId: String
    let base: BaseResource

    init(base: BaseResource, agentId: String) {
        self.base = base
        self.agentId = agentId
    }

    // MARK: - getCard

    /// Mirrors JS `a2a.getCard()` →
    /// `GET /.well-known/:agentId/agent-card.json`. Returns the A2A agent
    /// card metadata document.
    public func getCard() async throws -> AgentCard {
        try await base.request("/.well-known/\(agentId)/agent-card.json")
    }

    // MARK: - sendMessage

    /// Mirrors JS `a2a.sendMessage(params)` → `POST /a2a/:agentId` with a
    /// JSON-RPC 2.0 envelope (`method: "message/send"`).
    public func sendMessage(_ params: MessageSendParams) async throws -> SendMessageResponse {
        let body = Self.jsonRpcBody(method: "message/send", params: params)
        return try await base.request(
            "/a2a/\(agentId)",
            method: .POST,
            body: .json(body)
        )
    }

    // MARK: - sendStreamingMessage

    /// Mirrors JS `a2a.sendStreamingMessage(params)` → `POST /a2a/:agentId`
    /// with `method: "message/stream"` and `stream: true`. Returns a stream
    /// of `JSONValue` payloads decoded from the SSE event stream. Each
    /// yielded value is a `SendStreamingMessageResponse` JSON-RPC envelope.
    public func sendStreamingMessage(
        _ params: MessageSendParams
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        let body = Self.jsonRpcBody(method: "message/stream", params: params)
        let response = try await base.streamingRequest(
            "/a2a/\(agentId)",
            method: .POST,
            body: .json(body)
        )
        return Self.decodeEvents(from: response.bytes)
    }

    // MARK: - getTask

    /// Mirrors JS `a2a.getTask(params)` → `POST /a2a/:agentId` with
    /// `method: "tasks/get"`.
    public func getTask(_ params: TaskQueryParams) async throws -> GetTaskResponse {
        let body = Self.jsonRpcBody(method: "tasks/get", params: params)
        return try await base.request(
            "/a2a/\(agentId)",
            method: .POST,
            body: .json(body)
        )
    }

    // MARK: - cancelTask

    /// Mirrors JS `a2a.cancelTask(params)` → `POST /a2a/:agentId` with
    /// `method: "tasks/cancel"`. JS returns `Task` directly, so we decode
    /// the JSON-RPC envelope's `result` field.
    public func cancelTask(_ params: TaskQueryParams) async throws -> A2ATask {
        let body = Self.jsonRpcBody(method: "tasks/cancel", params: params)
        let envelope: SendMessageResponse = try await base.request(
            "/a2a/\(agentId)",
            method: .POST,
            body: .json(body)
        )
        if let error = envelope.error {
            throw MastraClientError(
                status: 0,
                statusText: "JSON-RPC error",
                message: "A2A cancelTask error \(error.code): \(error.message)"
            )
        }
        guard let result = envelope.result else {
            throw MastraClientError(
                status: 0,
                statusText: "JSON-RPC error",
                message: "A2A cancelTask missing result"
            )
        }
        let data = try JSONEncoder().encode(result)
        return try JSONDecoder().decode(A2ATask.self, from: data)
    }

    // MARK: - Helpers

    /// Builds the JSON-RPC 2.0 envelope used by every A2A POST call. Mirrors
    /// JS behavior: generates a fresh UUID `id` per request.
    private static func jsonRpcBody<P: Encodable>(
        method: String,
        params: P
    ) -> JSONValue {
        let paramsValue: JSONValue
        do {
            let data = try JSONEncoder().encode(params)
            paramsValue = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            paramsValue = .null
        }
        return .object([
            "jsonrpc": .string("2.0"),
            "id": .string(UUID().uuidString),
            "method": .string(method),
            "params": paramsValue,
        ])
    }

    /// Decodes an SSE byte stream into JSON-RPC payloads, mirroring the JS
    /// client's streaming consumption. Each SSE `data:` line is parsed as
    /// JSON; `[DONE]` sentinels and empty frames are skipped.
    static func decodeEvents<S: AsyncSequence & Sendable>(
        from bytes: S
    ) -> AsyncThrowingStream<JSONValue, Error> where S.Element == UInt8 {
        let sseStream = SSEDecoder.events(from: bytes)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await event in sseStream {
                        let data = event.data
                        if data.isEmpty || data == "[DONE]" { continue }
                        guard
                            let payload = data.data(using: .utf8),
                            let json = try? JSONDecoder().decode(JSONValue.self, from: payload)
                        else { continue }
                        continuation.yield(json)
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
