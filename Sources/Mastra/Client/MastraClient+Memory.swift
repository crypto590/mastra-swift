import Foundation

public extension MastraClient {
    // MARK: - Thread accessors

    /// Mirrors JS `client.getMemoryThread({ threadId, agentId? })`. Returns a
    /// `MemoryThread` handle — no network call is made.
    nonisolated func memoryThread(
        threadId: String,
        agentId: String? = nil
    ) -> MemoryThread {
        MemoryThread(base: base, threadId: threadId, agentId: agentId)
    }

    /// Mirrors JS `client.listMemoryThreads(params?)` →
    /// `GET /memory/threads`.
    nonisolated func listMemoryThreads(
        _ params: ListMemoryThreadsParams = .init()
    ) async throws -> ListMemoryThreadsResponse {
        try await base.request("/memory/threads", query: params.queryItems)
    }

    /// Mirrors JS `client.getMemoryConfig(params)` →
    /// `GET /memory/config?agentId=...`.
    nonisolated func memoryConfig(
        _ params: GetMemoryConfigParams
    ) async throws -> GetMemoryConfigResponse {
        var query: [URLQueryItem] = [.init(name: "agentId", value: params.agentId)]
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request("/memory/config", query: query)
    }

    /// Mirrors JS `client.createMemoryThread(params)` →
    /// `POST /memory/threads?agentId=...`.
    /// JS returns `CreateMemoryThreadResponse = StorageThreadType`; we return
    /// both the decoded info and a `MemoryThread` handle for convenience.
    nonisolated func createMemoryThread(
        _ params: CreateMemoryThreadParams
    ) async throws -> MemoryThreadInfo {
        var query: [URLQueryItem] = [.init(name: "agentId", value: params.agentId)]
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/memory/threads",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
    }

    // MARK: - Messages

    /// Mirrors JS `client.listThreadMessages(threadId, opts?)`. The JS client
    /// switches between three URL shapes based on `networkId` / `agentId`;
    /// this method preserves that routing exactly.
    nonisolated func listThreadMessages(
        threadId: String,
        agentId: String? = nil,
        networkId: String? = nil,
        includeSystemReminders: Bool? = nil,
        requestContext: RequestContext? = nil
    ) async throws -> ListMemoryThreadMessagesResponse {
        var query: [URLQueryItem] = []
        let path: String
        if let networkId {
            path = "/memory/network/threads/\(threadId)/messages"
            query.append(.init(name: "networkId", value: networkId))
        } else if let agentId {
            path = "/memory/threads/\(threadId)/messages"
            query.append(.init(name: "agentId", value: agentId))
        } else {
            path = "/memory/threads/\(threadId)/messages"
        }
        if let includeSystemReminders {
            query.append(.init(
                name: "includeSystemReminders",
                value: String(includeSystemReminders)
            ))
        }
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(path, query: query)
    }

    /// Mirrors JS `client.deleteThread(threadId, opts?)` →
    /// `DELETE /memory/threads/:threadId` (agent path) or
    /// `DELETE /memory/network/threads/:threadId` (network path).
    nonisolated func deleteThread(
        threadId: String,
        agentId: String? = nil,
        networkId: String? = nil,
        requestContext: RequestContext? = nil
    ) async throws -> DeleteThreadResponse {
        var query: [URLQueryItem] = []
        let path: String
        if let agentId {
            path = "/memory/threads/\(threadId)"
            query.append(.init(name: "agentId", value: agentId))
        } else if let networkId {
            path = "/memory/network/threads/\(threadId)"
            query.append(.init(name: "networkId", value: networkId))
        } else {
            // JS passes an empty URL in this branch (bug parity); we require
            // one of the two to avoid a malformed request.
            path = "/memory/threads/\(threadId)"
        }
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(path, method: .DELETE, query: query)
    }

    /// Mirrors JS `client.saveMessageToMemory(params)` →
    /// `POST /memory/save-messages?agentId=...`.
    nonisolated func saveMessageToMemory(
        _ params: SaveMessageToMemoryParams
    ) async throws -> SaveMessageToMemoryResponse {
        var query: [URLQueryItem] = [.init(name: "agentId", value: params.agentId)]
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/memory/save-messages",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
    }

    // MARK: - Memory status / observational memory

    /// Mirrors JS `client.getMemoryStatus(agentId, requestContext?, opts?)` →
    /// `GET /memory/status?agentId=...`.
    nonisolated func memoryStatus(
        agentId: String,
        resourceId: String? = nil,
        threadId: String? = nil,
        requestContext: RequestContext? = nil
    ) async throws -> GetMemoryStatusResponse {
        var query: [URLQueryItem] = [.init(name: "agentId", value: agentId)]
        if let resourceId { query.append(.init(name: "resourceId", value: resourceId)) }
        if let threadId { query.append(.init(name: "threadId", value: threadId)) }
        if let encoded = requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request("/memory/status", query: query)
    }

    /// Mirrors JS `client.getObservationalMemory(params)` →
    /// `GET /memory/observational-memory`.
    nonisolated func observationalMemory(
        _ params: GetObservationalMemoryParams
    ) async throws -> GetObservationalMemoryResponse {
        var query = params.queryItems
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request("/memory/observational-memory", query: query)
    }

    /// Mirrors JS `client.awaitBufferStatus(params)` →
    /// `POST /memory/observational-memory/buffer-status`.
    nonisolated func awaitBufferStatus(
        _ params: AwaitBufferStatusParams
    ) async throws -> AwaitBufferStatusResponse {
        var query: [URLQueryItem] = []
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/memory/observational-memory/buffer-status",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
    }

    // MARK: - Working memory

    /// Mirrors JS `client.getWorkingMemory({ agentId, threadId, resourceId? })`
    /// → `GET /memory/threads/:threadId/working-memory?agentId=...&resourceId=...`.
    /// The JS client always appends `resourceId` (even when undefined); we
    /// preserve that quirk by sending an empty string when not provided so
    /// the server receives the same URL shape.
    nonisolated func workingMemory(
        _ params: GetWorkingMemoryParams
    ) async throws -> JSONValue {
        var query: [URLQueryItem] = [
            .init(name: "agentId", value: params.agentId),
            .init(name: "resourceId", value: params.resourceId ?? ""),
        ]
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/memory/threads/\(params.threadId)/working-memory",
            query: query
        )
    }

    /// Mirrors JS `client.updateWorkingMemory({ agentId, threadId, workingMemory, resourceId? })` →
    /// `POST /memory/threads/:threadId/working-memory?agentId=...`.
    @discardableResult
    nonisolated func updateWorkingMemory(
        _ params: UpdateWorkingMemoryParams
    ) async throws -> JSONValue {
        var query: [URLQueryItem] = [.init(name: "agentId", value: params.agentId)]
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request(
            "/memory/threads/\(params.threadId)/working-memory",
            method: .POST,
            query: query,
            body: .json(params.body())
        )
    }

    // MARK: - Search memory

    /// Mirrors JS `client.searchMemory({ agentId, resourceId, threadId?, searchQuery, memoryConfig?, requestContext? })`
    /// → `GET /memory/search?...`. `memoryConfig` is JSON-stringified into the
    /// query string exactly as the JS client does.
    nonisolated func searchMemory(
        _ params: SearchMemoryParams
    ) async throws -> MemorySearchResponse {
        var query: [URLQueryItem] = [
            .init(name: "searchQuery", value: params.searchQuery),
            .init(name: "resourceId", value: params.resourceId),
            .init(name: "agentId", value: params.agentId),
        ]
        if let threadId = params.threadId {
            query.append(.init(name: "threadId", value: threadId))
        }
        if let memoryConfig = params.memoryConfig {
            let data = try JSONEncoder().encode(memoryConfig)
            if let str = String(data: data, encoding: .utf8) {
                query.append(.init(name: "memoryConfig", value: str))
            }
        }
        if let encoded = params.requestContext?.base64Encoded() {
            query.append(.init(name: "requestContext", value: encoded))
        }
        return try await base.request("/memory/search", query: query)
    }
}
