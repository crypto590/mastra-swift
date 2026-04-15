import Foundation

/// Mirrors `@mastra/core/request-context`'s `RequestContext` for the client side.
/// The server expects a flat key/value map base64-encoded as a `requestContext` query param.
public struct RequestContext: Sendable, Hashable, ExpressibleByDictionaryLiteral {
    public var entries: [String: JSONValue]
    public init(_ entries: [String: JSONValue] = [:]) { self.entries = entries }
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self.entries = Dictionary(uniqueKeysWithValues: elements)
    }
    public mutating func set(_ key: String, _ value: JSONValue) { entries[key] = value }

    /// Base64 of the UTF-8-encoded JSON representation, matching the JS client.
    public func base64Encoded() -> String? {
        guard !entries.isEmpty,
              let data = try? JSONEncoder().encode(entries) else { return nil }
        return data.base64EncodedString()
    }

    /// Returns the leading `?requestContext=...` (or `&requestContext=...`) query fragment.
    public func queryFragment(delimiter: String = "?") -> String {
        guard let encoded = base64Encoded(),
              let escaped = encoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return ""
        }
        return "\(delimiter)requestContext=\(escaped)"
    }
}
