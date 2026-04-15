import Foundation

public enum HTTPMethod: String, Sendable {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
}

public struct HTTPRequest: Sendable {
    public var method: HTTPMethod
    /// Path including the API prefix already applied (e.g. `/api/agents`).
    public var fullPath: String
    public var query: [URLQueryItem]
    public var headers: [String: String]
    public var body: HTTPBody?
    /// When true, the response body is delivered as a stream and not buffered.
    public var stream: Bool

    public init(
        method: HTTPMethod = .GET,
        fullPath: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: HTTPBody? = nil,
        stream: Bool = false
    ) {
        self.method = method
        self.fullPath = fullPath
        self.query = query
        self.headers = headers
        self.body = body
        self.stream = stream
    }
}

public enum HTTPBody: Sendable {
    case json(JSONValue)
    case data(Data, contentType: String)
    case multipart([MultipartPart])
}

public struct MultipartPart: Sendable {
    public let name: String
    public let filename: String?
    public let contentType: String?
    public let data: Data
    public init(name: String, filename: String? = nil, contentType: String? = nil, data: Data) {
        self.name = name
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
}

public struct HTTPResponse: Sendable {
    public let status: Int
    public let statusText: String
    public let headers: [String: String]
    public let body: Data

    public init(status: Int, statusText: String, headers: [String: String], body: Data) {
        self.status = status
        self.statusText = statusText
        self.headers = headers
        self.body = body
    }
}

/// A streaming response. The bytes sequence yields raw bytes as they arrive.
public struct HTTPStreamingResponse: Sendable {
    public let status: Int
    public let statusText: String
    public let headers: [String: String]
    public let bytes: AsyncThrowingStream<UInt8, Error>

    public init(
        status: Int,
        statusText: String,
        headers: [String: String],
        bytes: AsyncThrowingStream<UInt8, Error>
    ) {
        self.status = status
        self.statusText = statusText
        self.headers = headers
        self.bytes = bytes
    }
}
