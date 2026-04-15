import Foundation

/// Mirrors JS `ProcessorProvider` from `client-js/src/resources/processor-provider.ts`.
/// Acquire via `MastraClient.processorProvider(id:)`.
public struct ProcessorProvider: Sendable {
    public let providerId: String
    let base: BaseResource

    init(base: BaseResource, providerId: String) {
        self.base = base
        self.providerId = providerId
    }

    /// Mirrors JS `details()` →
    /// `GET /processor-providers/:providerId`.
    public func details() async throws -> GetProcessorProviderResponse {
        try await base.request(
            "/processor-providers/\(encoded(providerId))"
        )
    }

    /// Matches JS `encodeURIComponent`; required for `providerId` safety.
    private func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
