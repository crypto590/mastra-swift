import Foundation

/// Equivalent of JS `Conversations` resource. Methods map to `create`,
/// `retrieve`, `delete`, with a nested `items` handle exposing `list`.
/// Paths match `/v1/conversations` exactly.
///
/// Acquire an instance via `MastraClient.conversations`.
public struct Conversations: Sendable {
    let base: BaseResource

    /// Nested resource for listing conversation items. Mirrors JS
    /// `client.conversations.items.list(conversationId, ...)`.
    public var items: ConversationItems { ConversationItems(base: base) }

    init(base: BaseResource) {
        self.base = base
    }

    /// Mirrors JS `conversations.create(params)` → `POST /v1/conversations`.
    public func create(_ params: CreateConversationParams) async throws -> Conversation {
        try await base.request(
            "/v1/conversations",
            method: .POST,
            query: Self.requestContextQuery(params.requestContext),
            body: .json(params.body())
        )
    }

    /// Mirrors JS `conversations.retrieve(id, requestContext?)` →
    /// `GET /v1/conversations/:id`.
    public func retrieve(
        _ conversationId: String,
        requestContext: RequestContext? = nil
    ) async throws -> Conversation {
        try await base.request(
            "/v1/conversations/\(percentEncoded(conversationId))",
            method: .GET,
            query: Self.requestContextQuery(requestContext)
        )
    }

    /// Mirrors JS `conversations.delete(id, requestContext?)` →
    /// `DELETE /v1/conversations/:id`.
    @discardableResult
    public func delete(
        _ conversationId: String,
        requestContext: RequestContext? = nil
    ) async throws -> ConversationDeleted {
        try await base.request(
            "/v1/conversations/\(percentEncoded(conversationId))",
            method: .DELETE,
            query: Self.requestContextQuery(requestContext)
        )
    }

    // MARK: - Helpers

    static func requestContextQuery(_ context: RequestContext?) -> [URLQueryItem] {
        guard let context, let encoded = context.base64Encoded() else { return [] }
        return [URLQueryItem(name: "requestContext", value: encoded)]
    }

    private func percentEncoded(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? segment
    }
}

/// Equivalent of JS `ConversationItems`. Exposes `list(conversationId)` over
/// `GET /v1/conversations/:id/items`.
public struct ConversationItems: Sendable {
    let base: BaseResource

    init(base: BaseResource) {
        self.base = base
    }

    /// Mirrors JS `conversations.items.list(id, requestContext?)`.
    public func list(
        _ conversationId: String,
        requestContext: RequestContext? = nil
    ) async throws -> ConversationItemsPage {
        try await base.request(
            "/v1/conversations/\(percentEncoded(conversationId))/items",
            method: .GET,
            query: Conversations.requestContextQuery(requestContext)
        )
    }

    private func percentEncoded(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? segment
    }
}
