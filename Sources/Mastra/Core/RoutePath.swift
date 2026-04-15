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
}
