import Foundation

public extension MastraClient {
    /// Returns the `Conversations` resource handle. Mirrors JS
    /// `client.conversations`.
    nonisolated var conversations: Conversations {
        Conversations(base: base)
    }
}
