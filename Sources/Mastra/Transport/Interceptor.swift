import Foundation

/// An interceptor mutates outgoing requests just before they are sent.
/// Use this for auth, telemetry headers, request signing, etc.
public protocol Interceptor: Sendable {
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest
}

public enum AuthScheme: Sendable {
    case none
    case bearer(@Sendable () async throws -> String)
    case header(name: String, value: @Sendable () async throws -> String)
    case custom(@Sendable (HTTPRequest) async throws -> HTTPRequest)
}

extension AuthScheme: Interceptor {
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        switch self {
        case .none:
            return request
        case .bearer(let provider):
            var r = request
            let token = try await provider()
            r.headers["Authorization"] = "Bearer \(token)"
            return r
        case .header(let name, let provider):
            var r = request
            r.headers[name] = try await provider()
            return r
        case .custom(let block):
            return try await block(request)
        }
    }
}
