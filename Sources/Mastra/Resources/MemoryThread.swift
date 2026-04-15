import Foundation

/// Equivalent of JS `MemoryThread` resource. All methods map 1:1 to the JS
/// client; paths are preserved exactly. Acquire an instance via
/// `MastraClient.memoryThread(threadId:agentId:)`.
///
/// `agentId` is optional: when provided, it is appended as a `?agentId=...`
/// query param (the server will route through the agent's memory). When nil,
/// the server falls back to direct storage access.
public struct MemoryThread: Sendable {
    public let threadId: String
    public let agentId: String?
    let base: BaseResource

    init(base: BaseResource, threadId: String, agentId: String?) {
        self.base = base
        self.threadId = threadId
        self.agentId = agentId
    }

    // MARK: - Query helpers

    /// Query items including the optional `agentId` and request context.
    private func agentIdQuery(requestContext: RequestContext? = nil) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let agentId { items.append(.init(name: "agentId", value: agentId)) }
        if let encoded = requestContext?.base64Encoded() {
            items.append(.init(name: "requestContext", value: encoded))
        }
        return items
    }

    // MARK: - Get / update / delete

    /// Mirrors JS `memoryThread.get(requestContext?)` →
    /// `GET /memory/threads/:threadId`.
    public func get(
        requestContext: RequestContext? = nil
    ) async throws -> MemoryThreadInfo {
        try await base.request(
            "/memory/threads/\(threadId)",
            query: agentIdQuery(requestContext: requestContext)
        )
    }

    /// Mirrors JS `memoryThread.update(params)` →
    /// `PATCH /memory/threads/:threadId`.
    public func update(
        _ params: UpdateMemoryThreadParams
    ) async throws -> MemoryThreadInfo {
        try await base.request(
            "/memory/threads/\(threadId)",
            method: .PATCH,
            query: agentIdQuery(requestContext: params.requestContext),
            body: .json(params.body())
        )
    }

    /// Mirrors JS `memoryThread.delete(requestContext?)` →
    /// `DELETE /memory/threads/:threadId`.
    public func delete(
        requestContext: RequestContext? = nil
    ) async throws -> DeleteThreadResponse {
        try await base.request(
            "/memory/threads/\(threadId)",
            method: .DELETE,
            query: agentIdQuery(requestContext: requestContext)
        )
    }

    // MARK: - Messages

    /// Mirrors JS `memoryThread.listMessages(params)` →
    /// `GET /memory/threads/:threadId/messages`.
    public func listMessages(
        _ params: ListMemoryThreadMessagesParams = .init()
    ) async throws -> ListMemoryThreadMessagesResponse {
        var items: [URLQueryItem] = []
        if let agentId { items.append(.init(name: "agentId", value: agentId)) }
        if let resourceId = params.resourceId {
            items.append(.init(name: "resourceId", value: resourceId))
        }
        if let page = params.page {
            items.append(.init(name: "page", value: String(page)))
        }
        if let perPage = params.perPage {
            items.append(.init(name: "perPage", value: String(perPage)))
        }
        if let orderBy = params.orderBy {
            items.append(.init(name: "orderBy", value: Self.jsonString(orderBy)))
        }
        if let filter = params.filter {
            items.append(.init(name: "filter", value: Self.jsonString(filter)))
        }
        if let include = params.include {
            items.append(.init(name: "include", value: Self.jsonString(include)))
        }
        if let includeSystemReminders = params.includeSystemReminders {
            items.append(.init(
                name: "includeSystemReminders",
                value: String(includeSystemReminders)
            ))
        }
        if let encoded = params.requestContext?.base64Encoded() {
            items.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/memory/threads/\(threadId)/messages",
            query: items
        )
    }

    /// Mirrors JS `memoryThread.deleteMessages(messageIds, requestContext?)` →
    /// `POST /memory/messages/delete`. The JS client accepts either a string,
    /// an array of strings, an object with `id`, or an array of such objects;
    /// we expose the common cases (`String` and `[String]`).
    public func deleteMessages(
        _ messageIds: [String],
        requestContext: RequestContext? = nil
    ) async throws -> DeleteMessagesResponse {
        try await base.request(
            "/memory/messages/delete",
            method: .POST,
            query: agentIdQuery(requestContext: requestContext),
            body: .json(.object([
                "messageIds": .array(messageIds.map(JSONValue.string))
            ]))
        )
    }

    /// Convenience: single-id form mirroring the JS overload.
    public func deleteMessage(
        _ messageId: String,
        requestContext: RequestContext? = nil
    ) async throws -> DeleteMessagesResponse {
        try await deleteMessages([messageId], requestContext: requestContext)
    }

    // MARK: - Clone

    /// Mirrors JS `memoryThread.clone(params?)` →
    /// `POST /memory/threads/:threadId/clone`.
    public func clone(
        _ params: CloneMemoryThreadParams = .init()
    ) async throws -> CloneMemoryThreadResponse {
        try await base.request(
            "/memory/threads/\(threadId)/clone",
            method: .POST,
            query: agentIdQuery(requestContext: params.requestContext),
            body: .json(params.body())
        )
    }

    // MARK: - Helpers

    /// JSON-stringifies a `JSONValue` for use in a query parameter.
    /// Mirrors JS `JSON.stringify(value)` exactly.
    private static func jsonString(_ value: JSONValue) -> String {
        if let data = try? JSONEncoder().encode(value),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return ""
    }
}
