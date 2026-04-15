import Foundation

public protocol Transport: Sendable {
    /// Send a request and buffer the response body.
    func send(_ request: HTTPRequest) async throws -> HTTPResponse

    /// Send a request and stream the response body bytes.
    func sendStreaming(_ request: HTTPRequest) async throws -> HTTPStreamingResponse
}
