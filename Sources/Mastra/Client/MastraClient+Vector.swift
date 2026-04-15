import Foundation

public extension MastraClient {
    /// Mirrors JS `client.getVector(vectorName)`. Returns a `Vector` handle —
    /// no network call is made.
    nonisolated func vector(name: String) -> Vector {
        Vector(base: base, vectorName: name)
    }

    /// Mirrors JS `client.listVectors()` → `GET /vectors`.
    nonisolated func listVectors() async throws -> ListVectorsResponse {
        try await base.request("/vectors")
    }

    /// Mirrors JS `client.listEmbedders()` → `GET /embedders`.
    nonisolated func listEmbedders() async throws -> ListEmbeddersResponse {
        try await base.request("/embedders")
    }
}
