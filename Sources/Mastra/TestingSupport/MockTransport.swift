import Foundation
@_exported import Mastra

public final class MockTransport: Transport, @unchecked Sendable {
    public typealias Handler = @Sendable (HTTPRequest) async throws -> HTTPResponse
    public typealias StreamingHandler = @Sendable (HTTPRequest) async throws -> HTTPStreamingResponse

    private let lock = NSLock()
    private var _handler: Handler
    private var _streamingHandler: StreamingHandler
    private var _recorded: [HTTPRequest] = []

    public init(
        handler: @escaping Handler = { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data())
        },
        streamingHandler: @escaping StreamingHandler = { _ in
            HTTPStreamingResponse(
                status: 200,
                statusText: "OK",
                headers: [:],
                bytes: AsyncThrowingStream { $0.finish() }
            )
        }
    ) {
        self._handler = handler
        self._streamingHandler = streamingHandler
    }

    public var requests: [HTTPRequest] {
        lock.lock(); defer { lock.unlock() }
        return _recorded
    }

    public func setHandler(_ handler: @escaping Handler) {
        lock.lock(); defer { lock.unlock() }
        _handler = handler
    }

    public func setStreamingHandler(_ handler: @escaping StreamingHandler) {
        lock.lock(); defer { lock.unlock() }
        _streamingHandler = handler
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        record(request)
        let handler = currentHandler()
        return try await handler(request)
    }

    public func sendStreaming(_ request: HTTPRequest) async throws -> HTTPStreamingResponse {
        record(request)
        let handler = currentStreamingHandler()
        return try await handler(request)
    }

    private func record(_ request: HTTPRequest) {
        lock.lock(); defer { lock.unlock() }
        _recorded.append(request)
    }
    private func currentHandler() -> Handler {
        lock.lock(); defer { lock.unlock() }
        return _handler
    }
    private func currentStreamingHandler() -> StreamingHandler {
        lock.lock(); defer { lock.unlock() }
        return _streamingHandler
    }
}

public extension MockTransport {
    static func bytes(_ data: Data) -> AsyncThrowingStream<UInt8, Error> {
        AsyncThrowingStream { continuation in
            for byte in data { continuation.yield(byte) }
            continuation.finish()
        }
    }
    static func bytes(_ string: String) -> AsyncThrowingStream<UInt8, Error> {
        bytes(Data(string.utf8))
    }
}
