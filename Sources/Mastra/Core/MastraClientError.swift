import Foundation

public struct MastraClientError: Error, Sendable, CustomStringConvertible {
    public let status: Int
    public let statusText: String
    public let message: String
    public let body: JSONValue?
    public let rawBody: String?

    public init(status: Int, statusText: String, message: String, body: JSONValue? = nil, rawBody: String? = nil) {
        self.status = status
        self.statusText = statusText
        self.message = message
        self.body = body
        self.rawBody = rawBody
    }

    public var description: String { message }

    static func from(status: Int, statusText: String, rawBody: String) -> MastraClientError {
        var message = "HTTP error! status: \(status)"
        var parsed: JSONValue?
        if let data = rawBody.data(using: .utf8),
           let value = try? JSONDecoder().decode(JSONValue.self, from: data) {
            parsed = value
            if let canonical = try? String(
                data: JSONEncoder().encode(value),
                encoding: .utf8
            ) {
                message += " - \(canonical)"
            }
        } else if !rawBody.isEmpty {
            message += " - \(rawBody)"
        }
        return MastraClientError(
            status: status,
            statusText: statusText,
            message: message,
            body: parsed,
            rawBody: rawBody
        )
    }
}
