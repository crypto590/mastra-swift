import Foundation

public extension MastraClient {
    // MARK: - Tool Providers

    /// Mirrors JS `client.listToolProviders()` → `GET /tool-providers`.
    nonisolated func listToolProviders() async throws -> ListToolProvidersResponse {
        try await base.request("/tool-providers")
    }

    /// Mirrors JS `client.getToolProvider(providerId)` — returns a `ToolProvider` handle.
    nonisolated func toolProvider(id: String) -> ToolProvider {
        ToolProvider(base: base, providerId: id)
    }

    // MARK: - Processor Providers

    /// Mirrors JS `client.getProcessorProviders()` → `GET /processor-providers`.
    nonisolated func processorProviders() async throws -> GetProcessorProvidersResponse {
        try await base.request("/processor-providers")
    }

    /// Mirrors JS `client.getProcessorProvider(providerId)` — returns a `ProcessorProvider` handle.
    nonisolated func processorProvider(id: String) -> ProcessorProvider {
        ProcessorProvider(base: base, providerId: id)
    }
}
