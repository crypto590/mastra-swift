import Foundation

/// Mirrors JS `ToolProvider` from `client-js/src/resources/tool-provider.ts`.
/// Acquire via `MastraClient.toolProvider(id:)`.
public struct ToolProvider: Sendable {
    public let providerId: String
    let base: BaseResource

    init(base: BaseResource, providerId: String) {
        self.base = base
        self.providerId = providerId
    }

    /// Mirrors JS `listToolkits()` →
    /// `GET /tool-providers/:providerId/toolkits`.
    public func listToolkits() async throws -> ListToolProviderToolkitsResponse {
        try await base.request(
            "/tool-providers/\(encoded(providerId))/toolkits"
        )
    }

    /// Mirrors JS `listTools(params?)` →
    /// `GET /tool-providers/:providerId/tools`.
    public func listTools(
        _ params: ListToolProviderToolsParams = .init()
    ) async throws -> ListToolProviderToolsResponse {
        try await base.request(
            "/tool-providers/\(encoded(providerId))/tools",
            query: params.queryItems
        )
    }

    /// Mirrors JS `getToolSchema(toolSlug)` →
    /// `GET /tool-providers/:providerId/tools/:toolSlug/schema`.
    public func getToolSchema(
        toolSlug: String
    ) async throws -> GetToolProviderToolSchemaResponse {
        try await base.request(
            "/tool-providers/\(encoded(providerId))/tools/\(encoded(toolSlug))/schema"
        )
    }

    /// Matches JS `encodeURIComponent`; required for `id`/`slug` safety in the path.
    private func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? value
    }
}
