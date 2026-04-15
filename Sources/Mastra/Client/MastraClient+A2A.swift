import Foundation

public extension MastraClient {
    /// Returns an `A2A` handle bound to the given agent id. Mirrors JS
    /// `client.getA2A(agentId)`.
    nonisolated func a2a(agentId: String) -> A2A {
        A2A(base: base, agentId: agentId)
    }
}
