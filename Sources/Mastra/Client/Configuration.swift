import Foundation

public struct Configuration: Sendable {
    public var baseURL: URL
    /// Defaults to `/api`. Set to match server `apiPrefix`.
    public var apiPrefix: String
    public var retryPolicy: RetryPolicy
    public var headers: [String: String]
    public var auth: AuthScheme
    public var interceptors: [any Interceptor]
    public var requestContext: RequestContext?
    public var transport: (any Transport)?
    public var logger: any MastraLogger

    public init(
        baseURL: URL,
        apiPrefix: String = "/api",
        retryPolicy: RetryPolicy = .default,
        headers: [String: String] = [:],
        auth: AuthScheme = .none,
        interceptors: [any Interceptor] = [],
        requestContext: RequestContext? = nil,
        transport: (any Transport)? = nil,
        logger: any MastraLogger = NoopLogger()
    ) {
        self.baseURL = baseURL
        self.apiPrefix = apiPrefix
        self.retryPolicy = retryPolicy
        self.headers = headers
        self.auth = auth
        self.interceptors = interceptors
        self.requestContext = requestContext
        self.transport = transport
        self.logger = logger
    }
}
