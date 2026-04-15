import Foundation

public extension MastraClient {
    /// Returns the shared `Observability` resource handle.
    /// Mirrors JS `client.observability` (a property on the top-level client).
    nonisolated var observability: Observability {
        Observability(base: base)
    }
}
