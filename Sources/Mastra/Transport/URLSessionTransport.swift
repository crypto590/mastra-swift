import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class URLSessionTransport: Transport {
    public let baseURL: URL
    public let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let urlRequest = try buildURLRequest(request)
        #if canImport(FoundationNetworking)
        let (data, response) = try await session.asyncData(for: urlRequest)
        #else
        let (data, response) = try await session.data(for: urlRequest)
        #endif
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return HTTPResponse(
            status: http.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: http.statusCode),
            headers: Self.headers(from: http),
            body: data
        )
    }

    public func sendStreaming(_ request: HTTPRequest) async throws -> HTTPStreamingResponse {
        var streaming = request
        streaming.stream = true
        let urlRequest = try buildURLRequest(streaming)
        #if canImport(FoundationNetworking)
        throw MastraClientError(
            status: 0,
            statusText: "unsupported",
            message: "Streaming on Linux requires the optional NIO transport (not yet shipped). Use URLSessionTransport on Apple platforms."
        )
        #else
        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let stream = AsyncThrowingStream<UInt8, Error> { continuation in
            let task = Task {
                do {
                    for try await byte in bytes { continuation.yield(byte) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
        return HTTPStreamingResponse(
            status: http.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: http.statusCode),
            headers: Self.headers(from: http),
            bytes: stream
        )
        #endif
    }

    private func buildURLRequest(_ request: HTTPRequest) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        let basePath = baseURL.path.hasSuffix("/")
            ? String(baseURL.path.dropLast())
            : baseURL.path
        components.path = basePath + request.fullPath
        if !request.query.isEmpty { components.queryItems = request.query }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        for (k, v) in request.headers { urlRequest.setValue(v, forHTTPHeaderField: k) }
        if let body = request.body {
            try applyBody(body, to: &urlRequest)
        }
        return urlRequest
    }

    private func applyBody(_ body: HTTPBody, to req: inout URLRequest) throws {
        switch body {
        case .json(let value):
            if req.value(forHTTPHeaderField: "content-type") == nil
                && req.value(forHTTPHeaderField: "Content-Type") == nil {
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            req.httpBody = try JSONEncoder().encode(value)
        case .data(let data, let contentType):
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
            req.httpBody = data
        case .multipart(let parts):
            let boundary = "MastraSwiftBoundary-\(UUID().uuidString)"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            req.httpBody = MultipartEncoder.encode(parts, boundary: boundary)
        }
    }

    private static func headers(from response: HTTPURLResponse) -> [String: String] {
        var out: [String: String] = [:]
        for (k, v) in response.allHeaderFields {
            if let key = k as? String, let value = v as? String { out[key] = value }
        }
        return out
    }
}

enum MultipartEncoder {
    static func encode(_ parts: [MultipartPart], boundary: String) -> Data {
        var data = Data()
        for part in parts {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let filename = part.filename { disposition += "; filename=\"\(filename)\"" }
            data.append("\(disposition)\r\n".data(using: .utf8)!)
            if let ct = part.contentType {
                data.append("Content-Type: \(ct)\r\n".data(using: .utf8)!)
            }
            data.append("\r\n".data(using: .utf8)!)
            data.append(part.data)
            data.append("\r\n".data(using: .utf8)!)
        }
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
}

#if canImport(FoundationNetworking)
extension URLSession {
    func asyncData(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error { continuation.resume(throwing: error); return }
                guard let data, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse)); return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}
#endif
