import Foundation

public extension MastraClient {
    /// Returns the `Responses` resource handle. Mirrors JS
    /// `client.responses`.
    nonisolated var responses: Responses {
        Responses(base: base)
    }
}
