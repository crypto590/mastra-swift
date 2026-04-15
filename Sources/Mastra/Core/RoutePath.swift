import Foundation

public enum RoutePath {
    public struct InvalidPathError: Error, Sendable, CustomStringConvertible {
        public let path: String
        public var description: String {
            "Invalid route path: \"\(path)\". Path cannot contain '..', '?', or '#'"
        }
    }

    /// Mirrors the JS client `normalizeRoutePath`:
    /// - trims whitespace
    /// - rejects `..`, `?`, `#`
    /// - collapses repeated slashes
    /// - removes trailing slash
    /// - ensures leading slash (or empty for root)
    public static func normalize(_ path: String) throws -> String {
        var n = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.contains("..") || n.contains("?") || n.contains("#") {
            throw InvalidPathError(path: path)
        }
        while n.contains("//") { n = n.replacingOccurrences(of: "//", with: "/") }
        if n == "/" || n.isEmpty { return "" }
        if n.hasSuffix("/") { n.removeLast() }
        if !n.hasPrefix("/") { n = "/" + n }
        return n
    }

    /// Mirrors JavaScript `encodeURIComponent`. Escapes every character except
    /// the unreserved set (`A–Z a–z 0–9 - _ . ! ~ * ' ( )`). Critically, `/` IS
    /// escaped — an ID containing a slash becomes a single encoded segment, not
    /// multiple path segments. Do not use `.urlPathAllowed` for path segments;
    /// it leaves `/` and other reserved characters unescaped.
    public static func encodeURIComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? value
    }
}

extension CharacterSet {
    /// Unreserved set per RFC 3986 plus the extras JS `encodeURIComponent` leaves
    /// untouched: `! ~ * ' ( )`. Everything else (including `/`, `?`, `#`, `&`,
    /// `=`, `+`, `,`, `;`, `:`, `@`, `$`) gets percent-encoded.
    static let jsURIComponent: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        set.insert(charactersIn: "abcdefghijklmnopqrstuvwxyz")
        set.insert(charactersIn: "0123456789")
        set.insert(charactersIn: "-_.!~*'()")
        return set
    }()
}
