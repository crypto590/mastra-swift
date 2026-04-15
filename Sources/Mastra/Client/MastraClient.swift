import Foundation

/// Entry point for talking to a Mastra server. Holds shared configuration and
/// vends per-resource handles. Resource accessors are `nonisolated` so they can
/// be called from any context.
public actor MastraClient {
    public let configuration: Configuration
    private let baseResource: BaseResource

    public init(configuration: Configuration) throws {
        self.configuration = configuration
        self.baseResource = try BaseResource(configuration)
    }

    public init(
        baseURL: URL,
        apiPrefix: String = "/api",
        auth: AuthScheme = .none,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .default,
        transport: (any Transport)? = nil
    ) throws {
        try self.init(configuration: Configuration(
            baseURL: baseURL,
            apiPrefix: apiPrefix,
            retryPolicy: retryPolicy,
            headers: headers,
            auth: auth,
            transport: transport
        ))
    }

    /// Underlying resource accessor used by the per-resource handles. Public
    /// because resources in this module need access; treated as SPI by callers.
    public nonisolated var base: BaseResource { baseResource }
}
