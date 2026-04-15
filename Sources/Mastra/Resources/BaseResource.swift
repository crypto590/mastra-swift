import Foundation

/// Equivalent of JS `BaseResource`. Holds the configuration and dispatches
/// HTTP calls through the shared transport, applying retries, default headers,
/// auth, request-context, and apiPrefix normalization the same way `base.ts` does.
public struct BaseResource: Sendable {
    public let configuration: Configuration
    public let normalizedApiPrefix: String

    public init(_ configuration: Configuration) throws {
        self.configuration = configuration
        self.normalizedApiPrefix = try RoutePath.normalize(configuration.apiPrefix)
    }

    var transport: any Transport {
        configuration.transport ?? URLSessionTransport(baseURL: configuration.baseURL)
    }

    /// Buffered request returning a decoded value.
    public func request<T: Decodable & Sendable>(
        _ path: String,
        method: HTTPMethod = .GET,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: HTTPBody? = nil,
        as type: T.Type = T.self
    ) async throws -> T {
        let response = try await rawRequest(path, method: method, query: query, headers: headers, body: body)
        if T.self == JSONValue.self {
            if response.body.isEmpty { return JSONValue.null as! T }
            return try JSONDecoder().decode(T.self, from: response.body)
        }
        return try JSONDecoder().decode(T.self, from: response.body)
    }

    /// Buffered request returning the raw HTTPResponse.
    public func rawRequest(
        _ path: String,
        method: HTTPMethod = .GET,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: HTTPBody? = nil
    ) async throws -> HTTPResponse {
        let prepared = try await buildRequest(path, method: method, query: query, headers: headers, body: body, stream: false)
        return try await sendWithRetry(prepared) { req in
            try await transport.send(req)
        }
    }

    /// Streaming request returning the raw byte stream.
    public func streamingRequest(
        _ path: String,
        method: HTTPMethod = .POST,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: HTTPBody? = nil
    ) async throws -> HTTPStreamingResponse {
        let prepared = try await buildRequest(path, method: method, query: query, headers: headers, body: body, stream: true)
        // Streaming requests do not retry on error mid-stream; only the initial connect attempt is retried.
        return try await sendStreamingWithRetry(prepared)
    }

    private func sendStreamingWithRetry(_ request: HTTPRequest) async throws -> HTTPStreamingResponse {
        let policy = configuration.retryPolicy
        var lastError: Error?
        for attempt in 0...policy.maxRetries {
            do {
                let response = try await transport.sendStreaming(request)
                if response.status >= 400 {
                    var collected = Data()
                    for try await byte in response.bytes { collected.append(byte) }
                    let raw = String(data: collected, encoding: .utf8) ?? ""
                    throw MastraClientError.from(status: response.status, statusText: response.statusText, rawBody: raw)
                }
                return response
            } catch {
                lastError = error
                if !RetryPolicy.shouldRetry(error: error) { throw error }
                if attempt == policy.maxRetries { break }
                try await Task.sleep(for: policy.backoff(forAttempt: attempt))
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    private func sendWithRetry(
        _ request: HTTPRequest,
        send: @Sendable (HTTPRequest) async throws -> HTTPResponse
    ) async throws -> HTTPResponse {
        let policy = configuration.retryPolicy
        var lastError: Error?
        for attempt in 0...policy.maxRetries {
            do {
                let response = try await send(request)
                if response.status >= 400 {
                    let raw = String(data: response.body, encoding: .utf8) ?? ""
                    throw MastraClientError.from(status: response.status, statusText: response.statusText, rawBody: raw)
                }
                return response
            } catch {
                lastError = error
                if !RetryPolicy.shouldRetry(error: error) { throw error }
                if attempt == policy.maxRetries { break }
                try await Task.sleep(for: policy.backoff(forAttempt: attempt))
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    private func buildRequest(
        _ path: String,
        method: HTTPMethod,
        query: [URLQueryItem],
        headers: [String: String],
        body: HTTPBody?,
        stream: Bool
    ) async throws -> HTTPRequest {
        let normalizedPath = try RoutePath.normalize(path)
        let fullPath = normalizedApiPrefix + normalizedPath
        var combinedHeaders = configuration.headers
        for (k, v) in headers { combinedHeaders[k] = v }
        let combinedQuery = BaseResource.mergeRequestContext(
            callQuery: query,
            configContext: configuration.requestContext
        )
        var request = HTTPRequest(
            method: method,
            fullPath: fullPath,
            query: combinedQuery,
            headers: combinedHeaders,
            body: body,
            stream: stream
        )
        request = try await configuration.auth.intercept(request)
        for interceptor in configuration.interceptors {
            request = try await interceptor.intercept(request)
        }
        return request
    }

    /// Merges a per-call `requestContext` query item (if any) with the
    /// configuration-level `RequestContext` into a single encoded query item.
    /// Per-call entries win on key collision, matching the JS client's
    /// precedence. Never produces duplicate `requestContext` keys — different
    /// server frameworks disagree on first-vs-last-value semantics, so a
    /// duplicated key can silently shadow tenant/auth scoping.
    static func mergeRequestContext(
        callQuery: [URLQueryItem],
        configContext: RequestContext?
    ) -> [URLQueryItem] {
        let callIndex = callQuery.firstIndex(where: { $0.name == "requestContext" })
        guard configContext != nil || callIndex != nil else { return callQuery }

        let callEntries: [String: JSONValue] = callIndex
            .flatMap { callQuery[$0].value }
            .flatMap { Data(base64Encoded: $0) }
            .flatMap { try? JSONDecoder().decode([String: JSONValue].self, from: $0) }
            ?? [:]

        var merged = configContext?.entries ?? [:]
        for (key, value) in callEntries { merged[key] = value }

        var result = callQuery
        if let idx = callIndex { result.remove(at: idx) }
        if let encoded = RequestContext(merged).base64Encoded() {
            result.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return result
    }
}
